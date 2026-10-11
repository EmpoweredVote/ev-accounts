-- CC_0228 — the 445 INACTIVE CAL-ACCESS sources whose committee name STARTS with the surname.
-- 305 are somebody else's and are detached. 140 stay `disputed`.
--
-- Slice 4, and the companion to `CC_0227`, which did the same shape on LIVE rows. Worklist:
-- `.planning/todos/2026-10-10-cal-access-disputed-source-audit.md`.
--
-- Applies with `DATABASE_URL` (`ev_api`) — DML only, no DDL.
--
--
-- ══ WHY THESE ROWS MATTER AT ALL ═════════════════════════════════════════════════════════════
--
-- They are on INACTIVE politician rows, so nothing publishes and the `CC_0220` confirm-sweep
-- hazard does not apply. **The exposure is the dedupe merge.** `CC_0220` put 18 foreign committees
-- on Bryan Fish's and Angie Reyes English's LIVE rows by merging an inactive duplicate that
-- carried them. `CC_0221` found the same shape on eight more. Attribution first, merge second —
-- the ordering `CC_0216` established. Clearing these is what makes the dedupe programme safe.
--
-- 🟢 **All 445 carry ZERO contributions**, asserted below.
--
--
-- ══ THIS POPULATION IS MORE CONCENTRATED THAN THE LIVE ONE, AND THE SIGNALS ARE THINNER ══════
--
--                       in buckets of 5+    carrying a forename
--   live     (508)        290  (57%)          69  (14%)
--   inactive (445)        316  (71%)          31  ( 7%)
--
-- ⚠ **Only two of `CC_0227`'s three instruments survive here.** An inactive row has no
-- `office_current_holder` entry, so there is no seat to compare a committee's jurisdiction
-- against. What is left is the forename the committee carries, and bucket context.
--
-- 🟢 **But a third instrument turns out to be stronger here than anywhere:** the politician's
-- ALREADY-`not_applicable` rows. These buckets have been worked before, so the corpus often
-- already names the real owner.
--
--   **Diana Corona** holds **33** already-detached rows — Corona *city* council committees for
--   Button, Casillas, Connell, Husen, Kelly, Kindred, Rizvi, Speake and Tolstikov, plus other
--   people named Corona (Yolanda, Lorena, Carla, Malcolm, Benny, Merced, Sergio, Steve). Her six
--   disputed `CORONA FOR CITY COUNCIL 20xx` are the same artifact: "Corona" matched a CITY and a
--   SURNAME at once. Not one of the 39 is hers.
--   **George Fuller** holds **25** already-detached, nearly all **Jean Fuller**, the state senator.
--   **Lance Christensen** holds **14** — Judith, Carla, Tina, Kent, Jon, Maureen, Julie, Larry.
--
--
-- ══ 🔴 WHAT THE FORENAME PROTECTION CAUGHT, AND WHY IT IS NOT OPTIONAL ═══════════════════════
--
-- Two of these "buckets" are not buckets at all. They are a real person's COMPLETE committee set,
-- sitting in `disputed` by mistake:
--
--   **Tim Nader** — all **8** read `TIM`: Assembly, Judge 2016/2018/2020, Southwestern College
--     Board 2010/2014/2018, and `FRIENDS OF TIM`.
--   **David Patterson** — all **5** read `DAVID`: City Council, City Treasurer, Placer County
--     Board of Education twice, Treasurer.
--
-- ▶ **A bucket rule without the forename protection would have detached both sets in full.** The
-- protection is the reason this migration can use bucket size as evidence at all.
--
-- 🔴 **AND A DIMINUTIVE IS AGREEMENT, NOT CONFLICT.** Three small-bucket rows name `EDDIE` on an
-- Edward, `MIKE` on a Michael and `SUE` on a Susan. A conflict test that reads those as "a
-- different forename" would detach a person's own committees. They are LEFT, deliberately.
--
--
-- ══ THE RULE ═════════════════════════════════════════════════════════════════════════════════
--
--   bucket >= 5, forename absent  -> DETACH, unless named in `_big_keep`       289 rows
--   bucket <= 4                   -> DETACH only if named in `_small_foreign`   16 rows
--   everything else               -> LEFT `disputed`                           140 rows
--
-- ▶ The 140 left include the 31 forename matches, the 86 small-bucket rows with no signal at all
-- (`JOHNSON FOR CITY COUNCIL`), and 22 small-bucket rows carrying a tail that names nobody
-- (`SHANE, FRIENDS OF`, `PIAZZA FOR STATE SENATE, COMMITTEE FOR`). None can be settled from this
-- corpus and none is guessed at. They need a CAL-ACCESS candidate page or a Form 460 Part 5.

BEGIN;

DO $$
DECLARE
  v_cnt int;
  v_contrib0 bigint;
  n int;
BEGIN
  -- The one big-bucket row kept despite carrying no forename: it names the SAME seat, in the
  -- cycle between, as two rows that DO name her (`… HUNTINGTON BEACH … 2018; DIANA` and `… 2026;
  -- DIANA`). Detaching the middle one of three consecutive terms would be absurd.
  CREATE TEMP TABLE _big_keep (ext text, why text) ON COMMIT DROP;
  INSERT INTO _big_keep VALUES
    ('1444301','Diana Carey — HB Union High School District 2022, between her named 2018 and 2026');

  -- The 16 small-bucket rows (bucket <= 4) that name a different person outright.
  CREATE TEMP TABLE _small_foreign (ext text, why text) ON COMMIT DROP;
  INSERT INTO _small_foreign VALUES
    ('1247132','Winkler -> MICKIE'),        ('1327508','Mestas -> SARA'),
    ('1047677','Stiles -> LARRY'),          ('1332862','Chi -> opposing ROLAND'),
    ('1341096','Lang -> CHRIS LANG'),       ('1053427','Chung -> T. S.'),
    ('1233323','Zuniga -> JOSE'),           ('1315260','Crawford -> REV. WESLEY'),
    ('1343275','Harmon -> DEPUTY D.A. ERIC'),('1274779','Garrison -> PAUL'),
    ('1359935','Guzman -> GUADALUPE'),      ('1028745','Katz -> JUDGE JOSEPH A.'),
    ('1424730','Apodaca -> MALISSA'),       ('1374743','Chin -> JANET'),
    ('1324372','Gallegos -> D.A. PAUL'),    ('1254565','Gallegos -> recall of PAUL');

  CREATE TEMP TABLE _slice ON COMMIT DROP AS
    WITH base AS (
      SELECT s.id, s.essentials_politician_id AS pid, s.external_id,
             COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],'') AS cmte,
             split_part(regexp_replace(p.first_name,'^(Dr\.|Mr\.|Ms\.|Mrs\.)\s*','','i'),' ',1) AS fore,
             upper(p.last_name) AS surname
        FROM transparent_motivations.politician_sources s
        JOIN essentials.politicians p ON p.id = s.essentials_politician_id
       WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed'
         AND NOT p.is_active AND p.last_name IS NOT NULL
    ), f AS (
      SELECT * FROM base WHERE upper(cmte) LIKE surname || '%'
    ), b AS (
      SELECT pid, count(*) AS bucket FROM f GROUP BY pid
    )
    SELECT f.*, b.bucket,
           (length(f.fore) >= 3
            AND upper(f.cmte) ~ ('(^|[^A-Z])' || upper(f.fore) || '([^A-Z]|$)')) AS fore_ok
      FROM f JOIN b ON b.pid = f.pid;

  CREATE TEMP TABLE _srcs ON COMMIT DROP AS
    SELECT * FROM _slice
     WHERE (bucket >= 5 AND NOT fore_ok AND external_id NOT IN (SELECT ext FROM _big_keep))
        OR (bucket <= 4 AND external_id IN (SELECT ext FROM _small_foreign));

  -- ── PRE-VERIFY ────────────────────────────────────────────────────────────────────────────

  SELECT count(*) INTO v_cnt FROM _slice;
  IF v_cnt <> 445 THEN RAISE EXCEPTION 'CC_0228: inactive slice is %, expected 445', v_cnt; END IF;

  -- 🔴 Both hand-built lists must resolve EXACTLY. external_id is not globally unique; this is
  --    what proves each one is unambiguous inside this slice.
  SELECT count(*) INTO v_cnt FROM _slice WHERE external_id IN (SELECT ext FROM _big_keep);
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0228: _big_keep matched % slice rows, expected 1', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM _slice WHERE external_id IN (SELECT ext FROM _small_foreign);
  IF v_cnt <> 16 THEN RAISE EXCEPTION 'CC_0228: _small_foreign matched % slice rows, expected 16', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM _srcs;
  IF v_cnt <> 305 THEN RAISE EXCEPTION 'CC_0228: worklist is % sources, expected 305', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM _srcs WHERE bucket >= 5;
  IF v_cnt <> 289 THEN RAISE EXCEPTION 'CC_0228: % from big buckets, expected 289', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM _srcs WHERE bucket <= 4;
  IF v_cnt <> 16 THEN RAISE EXCEPTION 'CC_0228: % from small buckets, expected 16', v_cnt; END IF;

  -- 🔴🔴 THE CONTROL THAT MATTERS, and the one that protects Tim Nader's and David Patterson's
  --      entire genuine committee sets: no row carrying the politician's OWN forename may be
  --      detached. Agreement only ever protects.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE fore_ok;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0228: % rows carrying the politician''s OWN forename are in the detach list — stop', v_cnt;
  END IF;

  -- 🔴 The opposite control: every row must START with the surname, or the predicate drifted.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE upper(cmte) NOT LIKE surname || '%';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0228: % committees do NOT start with the surname', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM _srcs WHERE cmte = '';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0228: % sources have no committee name to judge', v_cnt; END IF;

  -- 🔴 Every politician in this slice must be INACTIVE. If one has been reactivated since the
  --    audit, this list is stale and the CC_0220 hazard is live rather than latent.
  SELECT count(*) INTO v_cnt
    FROM _slice x JOIN essentials.politicians p ON p.id = x.pid WHERE p.is_active;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0228: % slice rows now sit on ACTIVE politicians — re-audit before running', v_cnt;
  END IF;

  -- No money, so nothing publishes and nothing can be stranded.
  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN
    RAISE EXCEPTION 'CC_0228: the 305 sources carry % contributions, expected 0 — refusing', v_contrib0;
  END IF;

  -- ── THE CHANGE ────────────────────────────────────────────────────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET research_status = 'not_applicable',
         notes = COALESCE(s.notes,'')
                 || ' | NOT APPLICABLE CC_0228: the committee name begins with this surname but '
                 || 'belongs to a different person of that name. Settled by the forename the '
                 || 'committee itself carries, by bucket context, or by this politician''s own '
                 || 'already-adjudicated rows. Adjudicated 2026-10-11 on an INACTIVE row, so the '
                 || 'hazard cleared is the dedupe merge (the CC_0220 incident), not publication. '
                 || 'Re-attaching it to its real owner is a separate, evidenced step.',
         updated_at = now()
    FROM _srcs x
   WHERE s.id = x.id AND s.research_status = 'disputed';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 305 THEN RAISE EXCEPTION 'CC_0228: updated % rows, expected 305', n; END IF;

  -- ── POST-VERIFY ───────────────────────────────────────────────────────────────────────────

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _srcs x ON x.id = s.id
   WHERE s.research_status = 'not_applicable';
  IF v_cnt <> 305 THEN RAISE EXCEPTION 'CC_0228: % reached not_applicable, expected 305', v_cnt; END IF;

  -- 🔴 Counting what is LEFT is what catches an over-wide UPDATE; ROW_COUNT cannot.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _slice x ON x.id = s.id
   WHERE s.research_status = 'disputed';
  IF v_cnt <> 140 THEN RAISE EXCEPTION 'CC_0228: % of the slice still disputed, expected 140', v_cnt; END IF;

  -- 🔴🔴 Tim Nader's 8 and David Patterson's 5 — the two complete genuine sets — survive intact.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed'
     AND p.full_name IN ('Tim Nader','David Patterson');
  IF v_cnt <> 13 THEN
    RAISE EXCEPTION 'CC_0228: Nader + Patterson hold % disputed sources, expected 13 — a genuine set was detached', v_cnt;
  END IF;

  -- The Carey exception survived.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN _big_keep k ON k.ext = s.external_id
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0228: the big-bucket keep did not survive', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.notes LIKE '%CC_0228%' AND s.id NOT IN (SELECT id FROM _srcs);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0228: % sources outside the worklist carry a CC_0228 note', v_cnt; END IF;

  -- The rest of the disputed population is UNCHANGED: 733 - 305 = 428.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 428 THEN
    RAISE EXCEPTION 'CC_0228: % cal_access sources still disputed, expected 428', v_cnt;
  END IF;

  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN RAISE EXCEPTION 'CC_0228: the 305 sources now carry % contributions', v_contrib0; END IF;

  RAISE NOTICE 'CC_0228: 305 detached from inactive rows; 140 of the slice stay disputed; 428 disputed remain.';
END $$;

COMMIT;
