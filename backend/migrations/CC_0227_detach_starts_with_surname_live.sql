-- CC_0227 — the 508 LIVE CAL-ACCESS sources whose committee name STARTS with the politician's
-- surname. 294 are somebody else's and are detached. 214 stay `disputed`.
--
-- Slice 3 of the disputed-population audit. `CC_0223` was the no-surname bucket, `CC_0226` the
-- surname-not-leading bucket. Worklist: `.planning/todos/2026-10-10-cal-access-disputed-source-audit.md`.
--
-- Applies with `DATABASE_URL` (`ev_api`) — DML only, no DDL.
--
--
-- ══ 🔴 THIS SLICE IS A DIFFERENT PROBLEM FROM THE LAST TWO ═══════════════════════════════════
--
-- `CC_0223` and `CC_0226` were settleable by READING the committee name, because the name itself
-- named somebody else. Here the name starts with the surname, so **the name is consistent with
-- the attribution and proves nothing either way**. The worklist deferred these for exactly that
-- reason: "~486 Form 460 fetches for no voter-visible change".
--
-- It is not 486 fetches. Three in-corpus signals settle most of it, and the jurisdiction test that
-- carried `CC_0226` is NOT one of them — **500 of the 953 sit on politicians with no
-- `office_current_holder` row at all**, so there is no seat to compare against.
--
-- What does work:
--
--   1. 🟢 **THE FORENAME.** CAL-ACCESS names committees `SURNAME FOR OFFICE YEAR` or
--      `SURNAME, COMMITTEE TO ELECT FORENAME`. When the tail carries a forename it is decisive in
--      both directions — agreement is positive evidence, conflict is proof of a different person.
--   2. 🟢 **BUCKET CONTEXT.** A politician holding many committees of their surname, scattered
--      across unrelated jurisdictions, none naming them, is a name-match artifact in full. This is
--      `CC_0221`'s reasoning for Dan O'Brien's 44 — it detached the no-forename rows too.
--   3. 🟢 **THE POLITICIAN'S OWN COMMITTEES, already in this corpus.** The `CC_0226` instrument.
--
-- ⚠ **PR #972 tried a forename test and abandoned it**, reporting 135 flagged of 510 and "every
-- one of the 22 I read is a false positive" — `FRIENDS OF TED` on Ted Lieu, `RE ELECT FIONA` on
-- Fiona Ma. Read closely, those examples are forename **agreements** that the detector called
-- conflicts. The signal is real; that implementation was inverted. This migration therefore uses
-- agreement only to PROTECT a row, never to detach one, and every detachment was read by hand.
--
-- 🔴 **A PARSE ARTIFACT THE FORENAME TEST MUST SURVIVE:** `Dr. Monica Sanchez` has
-- `first_name = 'Dr.'`, so a naive comparison misses two rows that plainly read `SUPPORT MONICA`.
-- The honorific is stripped below, and the `length(fore) >= 3` guard stops a two-letter initial
-- from matching everything.
--
--
-- ══ WHAT THE BUCKETS CONTAIN ═════════════════════════════════════════════════════════════════
--
--   Pat Wilson, LIVE, Council Member of Rolling Hills (pop. ~1,900)       33 committees
--     Lori Wilson (Suisun City), Donald, Monica, Jayme, Chris, Doug (Grand Terrace), Hazel,
--     Dr. Sodonia Mae (SF D10), Abram, Bob — and FOUR about **Pete Wilson, the former Governor**
--     (`CITIZENS TO DEFEAT PETE`, `THE SPIRIT OF PETE`, `NORTHERN CALIFORNIA HISPANICS FOR PETE`).
--     Not one says Pat.
--   David L. Bradley, Mayor of Rancho Palos Verdes                         9 committees
--     Every one is **Tom Bradley** (Mayor of Los Angeles, 1973-93) or Omar Bradley (Compton).
--   Britt Huff, Rolling Hills Estates                                      6 committees
--     Every one is **Bob Huff**, the state senator — five of them `TAXPAYERS FOR BOB`.
--   Lisa Calderon, Assembly Member (elected 2024)                          5 committees
--     All the other Calderons; her own seat postdates every one of them.
--   Robert Luna, LIVE, Sheriff of Los Angeles County                      12 committees
--     Mickie Solorio, Sylvia, David, Bobby, Sammie, Daniel, Ray, George Luna.
--
-- 🔴 **AND TWO BUCKETS ARE MIXED, WHICH IS THE WHOLE REASON THIS IS NOT A PREDICATE:**
--
--   **Janice Hahn**, LIVE, Supervisor of Los Angeles County. Eight of her ten are **Kenneth P.
--   Hahn** (her father, the Supervisor) and **James Hahn** (her brother, Mayor of Los Angeles).
--   One reads `HAHN FOR SUPERVISOR 2016; NEIGHBORS UNITE SUPPORTING JANICE` — her exact seat.
--
--   **Rob Bonta**, Attorney General. Four are his. The fifth is
--   `BONTA FOR STATE ASSEMBLY 2021 … ; EDUCATORS AND HEALTHCARE PROFESSIONALS FOR **MIA**` —
--   **Mia Bonta**, who succeeded him in AD-18. One letter of difference, and a different person.
--
--
-- ══ THE RULE, AND WHAT IT DELIBERATELY DOES NOT REACH ════════════════════════════════════════
--
--   bucket >= 5, forename absent  -> DETACH, unless named in `_big_keep` below   248 rows
--   bucket <= 4                   -> DETACH only if named in `_small_foreign`     46 rows
--   bucket <= 4, no forename and no tail -> LEFT `disputed`                      123 rows
--
-- ▶ **The 123 are the honest residue.** `JOHNSON FOR CITY COUNCIL`, `ARELLANO FOR MAYOR`,
-- `PARRA 2007` — no forename, no place, no bucket to argue from. They cannot be settled from this
-- corpus and are not guessed at. Neither are the 41 singletons. Settling them needs a CAL-ACCESS
-- candidate page or a Form 460 Part 5, which is open work.
--
-- 🟢 **All 508 carry ZERO contributions**, asserted below. Nothing publishes either way; the
-- exposure is the next confirm sweep and the dedupe merge — the `CC_0220` hazard.
--
--
-- ══ 🔴 THE GENUINE RATE HERE IS NOTHING LIKE THE LAST SLICE ══════════════════════════════════
--
-- `CC_0226` found 10 genuine of 214, or 4.7%. Here **214 of 508 stay**, and a large share are
-- real independent-expenditure committees naming the right person in the right race:
--
--   Nathan Hochman   7 (all)   every one an IE supporting him for LA County DA
--   Kathryn Barger   7 (all)   IE committees across her 2016 and 2024 Supervisor races
--   Gavin Newsom     8 (all)   incl. `NEWSOM; CALIFORNIANS TO RECALL GAVIN` — an OPPOSE committee
--   Karen Ruth Bass  6 (all)   2022 and 2026 Mayor
--   Holly J. Mitchell, Heather Hutt, Jessica Caloza, Eunisses Hernandez, Nithya Raman,
--   Tony Thurmond, Eleni Kounalakis, Rex Richardson, Malia Cohen, Adrin Nazarian, and ~20 more.
--
-- ⚠ **That is the finding worth carrying forward.** A committee named `SURNAME FOR OFFICE` about
-- the right person IS their race — so this population is far richer in genuine rows than the one
-- where the surname sat mid-name. **Do not size the inactive-445 slice from `CC_0226`'s 4.7%.**
--
-- ⚠ Several of the kept rows are OPPOSE committees (`CALIFORNIANS TO RECALL GAVIN`,
-- `VOTE SMART CALIFORNIA OPPOSING` Ivan Altamirano, `OPPOSING PATTY` Lopez, the recall of Nancy
-- Tragarz). Publishing one as the politician's own fundraising is the harm ADR 0008 exists to
-- prevent. They stay withheld until typed and evidenced, exactly as `CC_0226`'s ten did.
--
--
-- ══ NOTE FORMAT ══════════════════════════════════════════════════════════════════════════════
--
-- `notes` is TEXT and most of this population already carries ` | ` appends from migration 1792
-- and `CA_0192`, so the committee name is read by regexp and never by a `::jsonb` cast. That cast
-- is what 500'd production earlier today (PR #979). ▶ **Never cast `notes` without a guard.**

BEGIN;

DO $$
DECLARE
  v_cnt int;
  v_contrib0 bigint;
  n int;
BEGIN
  -- ── THE 14 BIG-BUCKET ROWS THAT ARE KEPT DESPITE CARRYING NO FORENAME ─────────────────────
  -- Each was read and tied to the politician by their race, their seat, or their own committees.
  CREATE TEMP TABLE _big_keep (ext text, who text, why text) ON COMMIT DROP;
  INSERT INTO _big_keep VALUES
    ('1412931','Gavin Newsom',       'NEWSOM FOR GOVERNOR 2018 — his race'),
    ('1394881','Gavin Newsom',       'NEWSOM FOR GOVERNOR 2018 — his race'),
    ('1319132','Gavin Newsom',       'NEWSOM FOR GOVERNOR 2010 — he ran, then withdrew'),
    ('1254055','Gavin Newsom',       'AFRICAN AMERICANS FOR NEWSOM'),
    ('1254056','Gavin Newsom',       'LGBT COMMUNITY FOR NEWSOM'),
    ('1385362','Kathryn Barger',     'IE in her 2016 Supervisor race'),
    ('1465915','Kathryn Barger',     'IE in her 2024 Supervisor race'),
    ('1465846','Kathryn Barger',     'IE in her 2024 Supervisor race'),
    ('1455350','Karen Ruth Bass',    'ANGELENOS UNITED FOR — Bass for Mayor 2022'),
    ('1438600','Rob Bonta',          'EAST BAY UNITED FOR — his Assembly seat'),
    -- ⚠ These four are UNSETTLEABLE, not evidenced. Left disputed rather than guessed either way.
    ('1339784','John King',          'UNSETTLED: he genuinely ran for Supervisor (2014, 2026)'),
    ('1361834','John King',          'UNSETTLED: he genuinely ran for Supervisor (2014, 2026)'),
    ('1419893','Emmanuel J. Estrada','UNSETTLED: he became Baldwin Park mayor in 2020'),
    ('1471537','Juan Carrillo',      'UNSETTLED: he won AD-39 in 2022; Wendy Carrillo held AD-52');

  -- ── THE 46 SMALL-BUCKET ROWS (bucket <= 4) THAT ARE DEMONSTRABLY SOMEBODY ELSE'S ──────────
  -- Every one names a different forename, or a jurisdiction that is not the politician's.
  CREATE TEMP TABLE _small_foreign (ext text, who text) ON COMMIT DROP;
  INSERT INTO _small_foreign VALUES
    ('1445999','Nazarian -> BEVERLY HILLS; he is Los Angeles City Council'),
    ('1261217','Quintana -> RENE'),            ('1416983','Quintana -> Bulldog Victory Fund, Fresno'),
    ('1239795','Marshall -> GAIL'),            ('1474911','Delgadillo -> LILIANA'),
    ('1299358','Delgadillo -> ROCKY'),         ('1366806','Sherman -> city council; he is a US Rep'),
    ('1402945','Espinosa -> ROBERT A.'),       ('1330509','Moss -> STEVE'),
    ('1380518','Fenner -> WORTH F.'),          ('1246594','Parks -> CHARLES'),
    ('1371238','Solis -> SWEETWATER, Chula Vista'), ('1345148','Altamirano -> JUDGE DIANE'),
    ('1260102','Perkins -> T.'),               ('1412030','Irwin -> PATRICK'),
    ('1426387','Cochran -> Foresthill PUD recall slate'), ('1279855','Roos -> JESSICA BEAGLES'),
    ('1288484','Messina -> CONNIE'),           ('1031618','Merlo -> A. JOHN'),
    ('1282438','Ross -> BEVERLY'),             ('1221444','Mann -> JUDGE ART'),
    ('1300356','Mann -> CHRIS'),               ('1384018','Tang -> opposing BETTY'),
    ('1321063','Lieberman -> BELMONT'),        ('1418739','Herman -> GEORGE'),
    ('1269363','Cohen -> S.'),                 ('1389424','Acosta -> GEORGIA'),
    ('1423430','Pulido -> MIGUEL'),            ('1413145','Pulido -> RAVENSWOOD'),
    ('1395256','Pulido -> recall of Mayor MIGUEL'), ('1412261','McLean -> MISSION SPRINGS'),
    ('1279693','Wells -> RICHARD (DICK)'),     ('1408851','Kerr -> ALISON'),
    ('1405806','Kerr -> ADELANTO'),            ('1235012','Tucker -> DR SYLVIA'),
    ('1453587','Schultz -> TEHACHAPI'),        ('1263588','Kraut -> JONATHAN'),
    ('1066620','Marcus -> JUDGE STEPHEN'),     ('1447944','Hale -> GISELLE'),
    ('1309308','Melendez -> GUALBERTO J.'),    ('1069797','Elias -> BEN'),
    ('1407015','Hill -> JIM'),                 ('1372941','Hill -> JIM'),
    ('1232039','Hill -> SAMUEL'),              ('1313892','Scott -> ORLANDO'),
    ('1447959','Scott -> RIALTO; he is the San Francisco Police Chief');

  -- The slice, recomputed by the audit's own predicate rather than a pasted id list.
  CREATE TEMP TABLE _slice ON COMMIT DROP AS
    WITH base AS (
      SELECT s.id, s.essentials_politician_id AS pid, s.external_id,
             COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],'') AS cmte,
             -- 🔴 strip the honorific: 'Dr. Monica Sanchez' parses first_name = 'Dr.'
             split_part(regexp_replace(p.first_name,'^(Dr\.|Mr\.|Ms\.|Mrs\.)\s*','','i'),' ',1) AS fore,
             upper(p.last_name) AS surname
        FROM transparent_motivations.politician_sources s
        JOIN essentials.politicians p ON p.id = s.essentials_politician_id
       WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed'
         AND p.is_active AND p.last_name IS NOT NULL
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

  -- 1. The slice is the size the audit measured.
  SELECT count(*) INTO v_cnt FROM _slice;
  IF v_cnt <> 508 THEN RAISE EXCEPTION 'CC_0227: live slice is %, expected 508', v_cnt; END IF;

  -- 2. Both hand-built lists must resolve EXACTLY, with no id matching twice and none missing.
  --    🔴 external_id is not globally unique; this is what proves it is unambiguous HERE.
  SELECT count(*) INTO v_cnt FROM _slice WHERE external_id IN (SELECT ext FROM _big_keep);
  IF v_cnt <> 14 THEN RAISE EXCEPTION 'CC_0227: _big_keep matched % slice rows, expected 14', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM _slice WHERE external_id IN (SELECT ext FROM _small_foreign);
  IF v_cnt <> 46 THEN RAISE EXCEPTION 'CC_0227: _small_foreign matched % slice rows, expected 46', v_cnt; END IF;

  -- 3. The split, asserted both ways.
  SELECT count(*) INTO v_cnt FROM _srcs;
  IF v_cnt <> 294 THEN RAISE EXCEPTION 'CC_0227: worklist is % sources, expected 294', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM _srcs WHERE bucket >= 5;
  IF v_cnt <> 248 THEN RAISE EXCEPTION 'CC_0227: % from big buckets, expected 248', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM _srcs WHERE bucket <= 4;
  IF v_cnt <> 46 THEN RAISE EXCEPTION 'CC_0227: % from small buckets, expected 46', v_cnt; END IF;

  -- 4. 🔴🔴 THE CONTROL THAT MATTERS: not one row whose committee carries the politician's own
  --    forename may be detached. Forename agreement only ever PROTECTS a row — that is the
  --    discipline PR #972's inverted detector lacked.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE fore_ok;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0227: % rows carrying the politician''s OWN forename are in the detach list — stop', v_cnt;
  END IF;

  -- 5. 🔴 The opposite control: every row must START with the surname, or the predicate drifted.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE upper(cmte) NOT LIKE surname || '%';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0227: % committees do NOT start with the surname', v_cnt;
  END IF;

  -- 6. Every row carries a committee name; a blank would mean the predicate judged nothing.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE cmte = '';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0227: % sources have no committee name to judge', v_cnt; END IF;

  -- 7. No money, so nothing publishes and nothing can be stranded.
  --    (`contributions.politician_source_id` has NO foreign key — a strand would be silent.)
  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN
    RAISE EXCEPTION 'CC_0227: the 294 sources carry % contributions, expected 0 — refusing', v_contrib0;
  END IF;

  -- ── THE CHANGE ────────────────────────────────────────────────────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET research_status = 'not_applicable',
         notes = COALESCE(s.notes,'')
                 || ' | NOT APPLICABLE CC_0227: the committee name begins with this surname but '
                 || 'belongs to a different person of that name. Settled by the forename the '
                 || 'committee itself carries, by the jurisdiction, or by this politician''s own '
                 || 'committees elsewhere in this corpus. Adjudicated 2026-10-11; re-attaching it '
                 || 'to its real owner is a separate, evidenced step.',
         updated_at = now()
    FROM _srcs x
   WHERE s.id = x.id AND s.research_status = 'disputed';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 294 THEN RAISE EXCEPTION 'CC_0227: updated % rows, expected 294', n; END IF;

  -- ── POST-VERIFY ───────────────────────────────────────────────────────────────────────────

  -- 1. End state read back, not inferred from ROW_COUNT.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _srcs x ON x.id = s.id
   WHERE s.research_status = 'not_applicable';
  IF v_cnt <> 294 THEN RAISE EXCEPTION 'CC_0227: % reached not_applicable, expected 294', v_cnt; END IF;

  -- 2. 🔴 Counting what is LEFT is what catches an over-wide UPDATE; ROW_COUNT cannot.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _slice x ON x.id = s.id
   WHERE s.research_status = 'disputed';
  IF v_cnt <> 214 THEN RAISE EXCEPTION 'CC_0227: % of the slice still disputed, expected 214', v_cnt; END IF;

  -- 3. 🔴🔴 EVERY ONE OF THE 14 SURVIVED. The migration is pinned by what it refuses to change.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN _big_keep k ON k.ext = s.external_id
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 14 THEN RAISE EXCEPTION 'CC_0227: only % of the 14 big-bucket keeps survived, want 14', v_cnt; END IF;

  -- 4. Nothing outside the worklist was touched.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.notes LIKE '%CC_0227%' AND s.id NOT IN (SELECT id FROM _srcs);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0227: % sources outside the worklist carry a CC_0227 note', v_cnt; END IF;

  -- 5. The rest of the disputed population is UNCHANGED: 1,027 - 294 = 733.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 733 THEN
    RAISE EXCEPTION 'CC_0227: % cal_access sources still disputed, expected 733', v_cnt;
  END IF;

  -- 6. No contribution was created or stranded.
  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN RAISE EXCEPTION 'CC_0227: the 294 sources now carry % contributions', v_contrib0; END IF;

  RAISE NOTICE 'CC_0227: 294 detached from live politicians; 214 of the slice stay disputed; 733 disputed remain.';
END $$;

COMMIT;
