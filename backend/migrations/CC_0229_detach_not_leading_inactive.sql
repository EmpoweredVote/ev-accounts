-- CC_0229 — the last 64 CAL-ACCESS sources of the surname-NOT-LEADING shape: the ones on
-- INACTIVE politician rows. 63 are somebody else's and are detached. 1 is kept.
--
-- Slice 5, and the companion to `CC_0226`, which did this same shape on LIVE rows (204 detached
-- of 214). Worklist: `.planning/todos/2026-10-10-cal-access-disputed-source-audit.md`.
--
-- Applies with `DATABASE_URL` (`ev_api`) — DML only, no DDL.
--
--
-- ══ THE COUNT, AND A CORRECTION ══════════════════════════════════════════════════════════════
--
-- ⚠ A post-`CC_0228` sweep reported **74** disputed rows of this shape. That is right but
-- misleading: **64 are the inactive remainder, and the other 10 are `CC_0226`'s LIVE keeps** —
-- the genuine support/oppose committees that migration deliberately left (Nazarian, Keegan,
-- Richardson, Brock, Newsom, Altamirano, Horvath, Gharpetian, Rohrbach, Rizzotti). 64 is the
-- actionable figure and it matches the worklist's long-standing one.
--
-- 🟢 All 64 carry ZERO contributions. These sit on inactive rows, so the hazard cleared is the
-- **dedupe merge** — the `CC_0220` incident — not publication.
--
--
-- ══ WHAT THE MATCHER HIT: OVERWHELMINGLY A PLACE NAME ════════════════════════════════════════
--
--   IMPERIAL Irrigation District / County / Beach  -> Jay IMPERIAL        (11 of his 12)
--   the city of CORONA                             -> Diana CORONA        (8)
--   PASO ROBLES                                    -> Frances ROBLES      (3 of 4)
--   ALUM ROCK school district                      -> Michael ROCK        (4)
--   RANCHO SANTIAGO community college district     -> Dolores SANTIAGO    (3)
--   REED Union School District, the GILBERT Initiative, LOS ALTOS, ADELANTO, ALAMEDA
--
-- And the rest are a different person of the same surname — or a LONGER surname that merely
-- contains it: **MC SHANE** on Kristin *Shane* (3), **MC KAY** on Ben *Kay* (2), **DI DONATO**
-- on Nathan *Donato*, **BAUTISTA ZAVALA** on Saul *Zavala*, **BURKE MONTEZ** on Arturo *Montez*.
--
-- ▶ That last class is worth naming: the predicate `cmte LIKE '%' || surname || '%'` cannot tell
-- a surname from a surname that ENDS in it. Only reading the row does.
--
--
-- ══ 🟢 THE INSTRUMENT THAT SETTLED EVERY AMBIGUOUS ROW: THE POLITICIAN'S OWN DETACHED ROWS ═══
--
-- Four rows could not be judged from their own text. Each was settled — decisively — by what the
-- corpus had ALREADY adjudicated for that same politician:
--
--   `SALWAN AND OPPOSING BACON FOR MAYOR 2024 … ALAMEDA COUNTY`  on Roberta Bacon
--     -> her detached set names `BACON MAYOR OF FREMONT 2024; COMMITTEE TO ELECT **VINNIE**`.
--   `MAC DONALD FOR MAYOR AND HUBER FOR CITY COUNCIL 2014 … OXNARD`  on Tina Huber
--     -> hers names `HUBER FOR **OXNARD** CITY COUNCIL 2014, COMMITTEE TO ELECT **STEVE**`.
--        Same city, same year, named.
--   `BAUTISTA ZAVALA FOR SCHOOL BOARD 2026`  on Saul Zavala
--     -> `BAUTISTA ZAVALA FOR YUBA COMMUNITY COLLEGE BOARD 2028` is already `not_applicable`.
--   `RESIDENTS FOR A BETTER IMPERIAL, A COMMITTEE TO RECALL …`  on Jay Imperial
--     -> the full name recalls **Larry Grogan, Wally Leimgruber, Joe Maruca & Gary Wyatt**.
--        He is not among them. ⚠ The list was TRUNCATED in the first read; the answer was in
--        the part cut off. Read the whole value.
--
--
-- ══ 🔴 THE ONE THAT IS KEPT ══════════════════════════════════════════════════════════════════
--
--   `1277545  SOC - TO SUPPORT RECALL OF **JAY IMPERIAL** AND GARY TAYLOR`
--
-- It names him in full. It is a genuine OPPOSE committee about this person, and it sits in the
-- same bucket as eleven rows that merely matched the word "Imperial" as a place — which is
-- exactly why a bucket may never be detached wholesale without reading it.
--
-- It stays `disputed`, as `CC_0226`'s ten did: publishing a recall committee as the politician's
-- own fundraising is the harm ADR 0008 exists to prevent. Typing it needs a Form 460/496 read,
-- and it carries $0, so nothing would publish today.
--
-- ⚠ **1 genuine of 64 is 1.6%** — lower even than `CC_0226`'s 4.7% on the live half of this same
-- shape, and far below the 37% of the starts-with-surname shape (`CC_0227`/`CC_0228`). The rate
-- tracks the SHAPE, not the population. Never carry one slice's rate into another.
--
-- 🟢 **With this applied, no disputed CAL-ACCESS source of the no-surname or surname-not-leading
-- shapes remains unread, on a live or an inactive row.**

BEGIN;

DO $$
DECLARE
  v_cnt int;
  v_contrib0 bigint;
  n int;
BEGIN
  CREATE TEMP TABLE _slice ON COMMIT DROP AS
    SELECT s.id, s.essentials_politician_id AS pid, s.external_id,
           COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],'') AS cmte,
           upper(p.last_name) AS surname
      FROM transparent_motivations.politician_sources s
      JOIN essentials.politicians p ON p.id = s.essentials_politician_id
     WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed'
       AND NOT p.is_active AND p.last_name IS NOT NULL
       AND upper(COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],''))
             NOT LIKE upper(p.last_name) || '%'
       AND upper(COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],''))
             LIKE '%' || upper(p.last_name) || '%';

  -- The single keep: it names JAY IMPERIAL in full and is a recall committee about him.
  CREATE TEMP TABLE _keep (ext text, why text) ON COMMIT DROP;
  INSERT INTO _keep VALUES
    ('1277545','SOC - TO SUPPORT RECALL OF JAY IMPERIAL AND GARY TAYLOR — names him, an OPPOSE committee');

  CREATE TEMP TABLE _srcs ON COMMIT DROP AS
    SELECT * FROM _slice WHERE external_id NOT IN (SELECT ext FROM _keep);

  -- ── PRE-VERIFY ────────────────────────────────────────────────────────────────────────────

  SELECT count(*) INTO v_cnt FROM _slice;
  IF v_cnt <> 64 THEN RAISE EXCEPTION 'CC_0229: inactive not-leading slice is %, expected 64', v_cnt; END IF;

  -- 🔴 The keep must resolve to EXACTLY one row. external_id is not globally unique.
  SELECT count(*) INTO v_cnt FROM _slice WHERE external_id IN (SELECT ext FROM _keep);
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0229: the keep matched % slice rows, expected 1', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM _srcs;
  IF v_cnt <> 63 THEN RAISE EXCEPTION 'CC_0229: worklist is % sources, expected 63', v_cnt; END IF;

  -- 🔴 Inherited from CC_0223/CC_0226: not one committee may START with the surname. A row that
  --    does belongs to the CC_0227/CC_0228 shape and has already been judged under other rules.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE upper(cmte) LIKE surname || '%';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0229: % committees DO start with the surname — wrong slice', v_cnt;
  END IF;

  -- 🔴 The opposite control: every row MUST contain the surname, or the predicate selected on
  --    nothing and the gate above would pass vacuously.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE upper(cmte) NOT LIKE '%' || surname || '%';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0229: % committees do NOT contain the surname', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt FROM _srcs WHERE cmte = '';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0229: % sources have no committee name to judge', v_cnt; END IF;

  -- 🔴 Every politician here must still be INACTIVE. A reactivation since the audit makes the
  --    CC_0220 hazard live rather than latent, and this list stale.
  SELECT count(*) INTO v_cnt
    FROM _slice x JOIN essentials.politicians p ON p.id = x.pid WHERE p.is_active;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0229: % slice rows now sit on ACTIVE politicians — re-audit', v_cnt;
  END IF;

  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN
    RAISE EXCEPTION 'CC_0229: the 63 sources carry % contributions, expected 0 — refusing', v_contrib0;
  END IF;

  -- ── THE CHANGE ────────────────────────────────────────────────────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET research_status = 'not_applicable',
         notes = COALESCE(s.notes,'')
                 || ' | NOT APPLICABLE CC_0229: the committee carries this surname but not at '
                 || 'the front, and it belongs to somebody else — most often a PLACE (Imperial '
                 || 'Irrigation District, the city of Corona, Paso Robles, Alum Rock, Rancho '
                 || 'Santiago), a different person of the same surname, or a LONGER surname that '
                 || 'merely contains it (Mc Shane, Mc Kay, Di Donato, Bautista Zavala). Settled '
                 || 'by reading the committee name in full and against this politician''s own '
                 || 'already-adjudicated rows. Adjudicated 2026-10-11 on an INACTIVE row, so the '
                 || 'hazard cleared is the dedupe merge (the CC_0220 incident), not publication.',
         updated_at = now()
    FROM _srcs x
   WHERE s.id = x.id AND s.research_status = 'disputed';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 63 THEN RAISE EXCEPTION 'CC_0229: updated % rows, expected 63', n; END IF;

  -- ── POST-VERIFY ───────────────────────────────────────────────────────────────────────────

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _srcs x ON x.id = s.id
   WHERE s.research_status = 'not_applicable';
  IF v_cnt <> 63 THEN RAISE EXCEPTION 'CC_0229: % reached not_applicable, expected 63', v_cnt; END IF;

  -- 🔴 Count what is LEFT: exactly the one keep. ROW_COUNT cannot catch an over-wide UPDATE.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _slice x ON x.id = s.id
   WHERE s.research_status = 'disputed';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0229: % of the slice still disputed, expected 1', v_cnt; END IF;

  -- 🔴🔴 And it is the RIGHT one. The migration is pinned by what it refuses to change.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN _keep k ON k.ext = s.external_id
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0229: the Jay Imperial recall committee did not survive'; END IF;

  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.notes LIKE '%CC_0229%' AND s.id NOT IN (SELECT id FROM _srcs);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0229: % sources outside the worklist carry a CC_0229 note', v_cnt; END IF;

  -- The rest of the disputed population is UNCHANGED: 428 - 63 = 365.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 365 THEN
    RAISE EXCEPTION 'CC_0229: % cal_access sources still disputed, expected 365', v_cnt;
  END IF;

  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN RAISE EXCEPTION 'CC_0229: the 63 sources now carry % contributions', v_contrib0; END IF;

  RAISE NOTICE 'CC_0229: 63 detached from inactive rows; the Jay Imperial recall committee kept; 365 disputed remain.';
END $$;

COMMIT;
