-- CC_0223 — 103 foreign CAL-ACCESS committees are sitting on SEVEN LIVE politicians. Detach them.
--
-- Step 1 of 2 from the **disputed** audit (2026-10-10). `CC_0221`/`CC_0222` closed the `confirmed`
-- population; this is the first slice of the `disputed` one.
-- Worklist: `.planning/todos/2026-10-10-cal-access-disputed-source-audit.md`.
--
-- 🔴 **STEP 2 IS NOT THIS MIGRATION AND MUST NOT BE FOLDED INTO IT.** Sixteen of these committees
-- belong to politicians this corpus holds as LIVE INCUMBENTS — Henry Stern, Thomas Umberg, Maria
-- Elena Durazo, Debra Archuleta. **Attaching a source to them is a POSITIVE claim needing POSITIVE
-- evidence** (the candidate page or the Form 460). A committee name proves only whose a committee
-- is **not**. That is the `CC_0216` ordering: detach on the evidence you have, attach on the
-- evidence you get.
--
--
-- ══ WHAT THE AUDIT OF THE 1,336 DISPUTED SOURCES FOUND ═══════════════════════════════════════
--
-- The handoff measured this population by **money** and shelved it: only 2 of the 1,336 carry a
-- contribution. True, and the wrong axis. **827 of them sit on LIVE politician rows** — which is
-- the merge hazard `CC_0220` paid for, not a publishing problem.
--
-- ⚠ **THREE PREDICATES RAN BEFORE THE TRUE ONE. READING ROWS CAUGHT EVERY MISS.**
--
-- 1. A **forename** test said 705 of 707 live-row sources "do not name the politician". False —
--    those are surname-only local committees (`MOSS FOR SCHOOL BOARD 2014`), which `CC_0221`
--    already established is normal and evidence of nothing.
-- 2. A **surname-anywhere** test found 100 with no surname match at all. Real, but incomplete.
-- 3. 🔴 **A surname test PASSES WHEN THE POLITICIAN'S SURNAME IS SOMEBODY ELSE'S FORENAME.** The
--    pre-verify gate of this migration's first draft caught three it had missed, all on Karen
--    **Douglas**: `STREHL … FOR THE ELECTION OF DOUGLAS` and `PHIMISTER FOR JUDGE, CITIZENS FOR
--    DOUGLAS C.` — Douglas Strehl and Douglas C. Phimister. Same shape as Paulette Francis and
--    Francis Carbajal in `CC_0221`.
--
-- ▶ **The test that holds is whether the committee name STARTS with the politician's surname.**
-- California committees are named `SURNAME FOR OFFICE …` or `SURNAME, COMMITTEE TO ELECT FORENAME`.
-- **All 103 disputed sources on these seven rows fail it — not one begins with the surname.**
--
--     Francis De Leon Sanchez  e086df00   80   Van de Kamp · De Vore · De Maio · De Saulnier · …
--     Gregg Hart               21940b7c    8   Henry Stern
--     Dr. Corey A. Jackson     bbd7825a    5   Thomas Umberg
--     Karen Douglas            5d6cae71    4   Hardcastle · Douglas Strehl ×2 · Douglas Phimister
--     Jasmeet Kaur Bains       539874fc    3   Maria Elena Durazo
--     Steve Bennett            8c61cd23    2   Valladares
--     Phillip Chen             ed32efa5    1   Debra Archuleta (LA District Attorney 2024)
--                                       ─────
--                                        103
--
-- 🔴🔴 **FRANCIS DE LEON SANCHEZ'S 80 CAME FROM MATCHING THE PARTICLE "DE".** A two-letter token.
-- `VAN DE KAMP, FRIENDS OF` · `DE VORE IN '04` · `GRUPO DE HAWTHORNE DE PADRES LATINO` ·
-- `DE MAIO FOR MAYOR 2012, GAY FRIENDS SUPPORTING CARL`. A bigger bucket than Dan O'Brien's 44 in
-- `CC_0221`, and unlike those eight rows **this one is LIVE**.
--
-- ⚠ **These rows were already PARTLY cleaned; this is the residue.** Sanchez also carries 109
-- `not_applicable`, Douglas 38, Chen 10, Bains 8. A previous pass took the easy ones.
-- **A row that has been worked is not a row that is finished.**
--
--
-- ══ WHAT THIS MIGRATION DOES NOT TOUCH ═══════════════════════════════════════════════════════
--
-- **1,233 disputed sources remain and are deliberately left.** 215 of them carry the surname
-- somewhere but not at the front, and a read of 18 shows that bucket is **mostly foreign too** —
-- matched on **place names and common nouns**, not just surnames:
--
--     PRINCE FOR SAN GABRIEL VALLEY MUNICIPAL WATER DISTRICT   -> Jesse GABRIEL
--     NELSON FOR VILLA PARK CITY COUNCIL                       -> Traci PARK
--     RYU … GRIFFITH PARK FRIENDS SUPPORTING DAVID             -> Traci PARK
--     HENDRICKSON KING CITY COUNCIL 2012                       -> John KING   (King City, Monterey)
--     RESNICK FOR PERALTA COMMUNITY COLLEGE BOARD              -> Scarlet PERALTA
--     VOTE FOR PARKS                                           -> Grant PARKS
--
-- ⚠ **But roughly one in five of that bucket is a genuine SUPPORT or OPPOSE committee naming the
-- right person** (`PRICE FOR MAYOR 2022 AND OPPOSING REX RICHARDSON`, `… AND AGAINST BROCK FOR CITY
-- COUNCIL 2024`). Those must **not** be detached — they are correctly withheld and are blocked on
-- the same support/oppose rendering question as `CC_0221`'s three and the Newsom recall committee.
-- ▶ **That bucket needs reading row by row, not a predicate.** It is the next slice.
--
--
-- ══ WHY THIS IS SAFE, AND WHY IT STILL MATTERS ═══════════════════════════════════════════════
--
-- 🟢 **Not one of the 103 carries a contribution**, and `disputed` publishes nothing, so **no voter
-- page changes and no money moves.** Asserted before and after.
--
-- 🔴 The harm is latent and it is `CC_0220`'s: a `disputed` source on a LIVE politician is a loaded
-- gun. Any later pass that confirms by surname — which is exactly how all of this was created —
-- would publish another person's committee on a sitting officeholder.
--
-- Terminal state `not_applicable` per the operator ruling of 2026-10-09 recorded in `CC_0216`.

BEGIN;

DO $$
DECLARE
  v_cnt int;
  v_contrib0 bigint;
  n int;
BEGIN
  CREATE TEMP TABLE _rows (pid uuid, who text, expected int) ON COMMIT DROP;
  INSERT INTO _rows VALUES
    ('e086df00-1e48-4882-9594-82f4e9ee273c','Francis De Leon Sanchez', 80),
    ('21940b7c-2424-47e9-a649-077b0f827c2c','Gregg Hart',               8),
    ('bbd7825a-6778-4cca-81c8-8ef3ded55965','Dr. Corey A. Jackson',     5),
    ('5d6cae71-1ca7-43b5-80d6-2cc5faef81b7','Karen Douglas',            4),
    ('539874fc-489f-4643-9b1a-923aca6cc2c1','Jasmeet Kaur Bains',       3),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64','Steve Bennett',            2),
    ('ed32efa5-b455-4323-a12f-5fe79bc4ffd6','Phillip Chen',             1);

  -- Every disputed cal_access source on these seven rows. All 103 were read; all 103 are foreign.
  CREATE TEMP TABLE _srcs ON COMMIT DROP AS
    SELECT s.id, s.essentials_politician_id AS pid, s.external_id,
           COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],'') AS cmte,
           regexp_replace(regexp_replace(regexp_replace(lower(p.full_name),
             '^(dr\.|mr\.|ms\.|mrs\.)\s+',''), '\s+(jr\.|sr\.|ii|iii|iv)$',''), '.*\s','') AS surname
      FROM transparent_motivations.politician_sources s
      JOIN _rows r ON r.pid = s.essentials_politician_id
      JOIN essentials.politicians p ON p.id = s.essentials_politician_id
     WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';

  -- ── PRE-VERIFY ────────────────────────────────────────────────────────────────────────────

  -- 1. Exactly 103, split exactly as measured. 🔴 The TOTAL alone would pass if 80 moved between
  --    rows; the per-row check is what makes this a gate rather than a tally.
  SELECT count(*) INTO v_cnt FROM _srcs;
  IF v_cnt <> 103 THEN RAISE EXCEPTION 'CC_0223: worklist is % sources, expected 103', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM _rows r LEFT JOIN (SELECT pid, count(*) AS n FROM _srcs GROUP BY pid) g ON g.pid = r.pid
   WHERE COALESCE(g.n,0) <> r.expected;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0223: % of the 7 rows hold a different count than measured — re-audit', v_cnt;
  END IF;

  -- 2. 🔴🔴 THE CONTROL FOR THE WHOLE WORKLIST: not one committee name may START with the
  --    politician's surname. That is the test that survived three failed predicates, and if a
  --    single row passes it this migration is detaching something it has not read.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE upper(cmte) LIKE upper(surname) || '%';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0223: % committees DO start with the politician surname — stop and read them', v_cnt;
  END IF;

  -- 3. Every one carries a committee name. A blank would mean the predicate judged nothing.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE cmte = '';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0223: % sources have no committee name to judge', v_cnt; END IF;

  -- 4. 🔴 ALL SEVEN ARE LIVE — the reason this is not deferrable. Asserted, not described.
  SELECT count(*) INTO v_cnt FROM _rows r JOIN essentials.politicians p ON p.id = r.pid
   WHERE p.is_active AND p.full_name = r.who;
  IF v_cnt <> 7 THEN
    RAISE EXCEPTION 'CC_0223: % of the 7 rows are live and named as expected, want 7', v_cnt;
  END IF;

  -- 5. No money, so nothing publishes and nothing can be stranded.
  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN
    RAISE EXCEPTION 'CC_0223: the 103 sources carry % contributions, expected 0 — refusing', v_contrib0;
  END IF;

  -- ── THE CHANGE ────────────────────────────────────────────────────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET research_status = 'not_applicable',
         notes = COALESCE(s.notes,'')
                 || ' | NOT APPLICABLE CC_0223: the committee''s own name is a different person''s. '
                 || 'Attached by a name match that hit a particle, a place name or somebody else''s '
                 || 'forename. Adjudicated 2026-10-10; re-attaching it to its real owner is a '
                 || 'separate, evidenced step.',
         updated_at = now()
    FROM _srcs x
   WHERE s.id = x.id AND s.research_status = 'disputed';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 103 THEN RAISE EXCEPTION 'CC_0223: updated % rows, expected 103', n; END IF;

  -- ── POST-VERIFY ───────────────────────────────────────────────────────────────────────────

  -- 1. End state, read back rather than inferred from ROW_COUNT.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _srcs x ON x.id = s.id
   WHERE s.research_status = 'not_applicable';
  IF v_cnt <> 103 THEN RAISE EXCEPTION 'CC_0223: % reached not_applicable, expected 103', v_cnt; END IF;

  -- 2. 🔴 Counting what is LEFT catches an over-wide UPDATE; ROW_COUNT cannot. These seven rows
  --    must now hold ZERO disputed cal_access sources.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.pid = s.essentials_politician_id
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0223: the 7 rows still hold % disputed sources, expected 0', v_cnt;
  END IF;

  -- 3. Nothing outside the seven rows was touched.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.notes LIKE '%CC_0223%' AND s.essentials_politician_id NOT IN (SELECT pid FROM _rows);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0223: % sources outside the 7 rows carry a CC_0223 note', v_cnt; END IF;

  -- 4. 🔴 The rest of the disputed population is UNCHANGED — including the support/oppose
  --    committees this migration deliberately refuses to touch.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 1233 THEN
    RAISE EXCEPTION 'CC_0223: % cal_access sources still disputed, expected 1,233', v_cnt;
  END IF;

  -- 5. No contribution touched or stranded. It was 0 before and must be 0 now.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_cnt <> v_contrib0 THEN
    RAISE EXCEPTION 'CC_0223: the 103 sources carried % contributions and now carry %', v_contrib0, v_cnt;
  END IF;

  RAISE NOTICE 'CC_0223: 103 foreign committees detached from 7 LIVE rows, 0 money moved, 1,233 disputed left';
END $$;

COMMIT;
