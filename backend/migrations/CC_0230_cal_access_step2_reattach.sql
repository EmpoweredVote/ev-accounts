-- CC_0230 — STEP 2 of `CC_0223`: re-attach the CAL-ACCESS committees whose real owner this
-- corpus holds. The POSITIVE half of the disputed-source programme.
--
-- `CC_0223` detached 19 committees from five live politicians they did not belong to, and said
-- so in every note: "re-attaching it to its real owner is a separate, evidenced step." This is
-- that step. Worklist: `.planning/todos/2026-10-10-cal-access-disputed-source-audit.md`.
--
-- Applies with `DATABASE_URL` (`ev_api`) — DML only, no DDL.
--
--
-- ══ 🔴 WHY THIS MIGRATION IS A DIFFERENT KIND OF WORK ════════════════════════════════════════
--
-- Detaching needed only proof of whose a committee is NOT. **Attaching is a positive claim on a
-- LIVE officeholder — the one action in this programme that can create a NEW false attribution.**
-- So nothing here moves on a name match. Every re-attachment is carried by the CAL-ACCESS
-- CANDIDATE page, which lists a candidate's committees by filer id and is therefore a primary
-- source naming the candidate AND the committee together.
--
--   /Campaign/Candidates/Detail.aspx?id=1374151  -> Henry Stern
--   /Campaign/Candidates/Detail.aspx?id=1241318  -> Thomas Umberg
--   /Campaign/Candidates/Detail.aspx?id=1395750  -> Maria Elena Durazo
--
-- Read 2026-10-11 in a Playwright context (cal-access.sos.ca.gov is behind Incapsula and returns
-- a 212-byte stub at HTTP 200 to curl; load the homepage first to set the cookie).
--
--
-- ══ THE 19, AND WHAT EACH ONE TURNED OUT TO BE ═══════════════════════════════════════════════
--
--   9  RE-ATTACHED, confirmed   on the candidate page, by filer id
--   3  RE-ATTACHED, withheld    name the person but are ABSENT from their candidate page,
--                               so they are OUTSIDE spending, not the person's own money
--   1  DISPROVED                stays detached, note upgraded from "unverified" to "disproved"
--   4  UNSETTLED                stay detached; the evidence route was tried and is closed
--   2  VALLADARES               stay detached, per the standing ruling
--
--
-- ══ 🔴🔴 TWO DETECTORS THAT WOULD HAVE MISLED THIS MIGRATION ═════════════════════════════════
--
-- 1. **The race history on a CAL-ACCESS candidate page covers STATE races ONLY.** Maria Elena
--    Durazo is an LA County Supervisor candidate in 2026 — her own page carries
--    `DURAZO FOR SUPERVISOR 2026 ATTORNEY FEES FUND` (1480691) — and her race list does not
--    mention it. ▶ So Henry Stern's race list, which shows only State Senate District 27 in
--    2016/2020/2024, is NOT evidence against `STERN FOR SUPERVISOR 2022`. A negative read off
--    that list is vacuous for any county or municipal race.
--
-- 2. **The filer phone groups by FILING AGENT, not by person — measured here, not assumed.**
--    (916) 285-5733 is shared by ALL FIVE of Henry Stern's committees AND FOUR of Thomas
--    Umberg's. Two different state senators, one treasurer. `CC_0216` already graded this signal
--    weak; this is a cleaner demonstration than the one on record.
--
--
-- ══ ✅ THE 9 CARRIED BY THE CANDIDATE PAGE ═══════════════════════════════════════════════════
--
--   Gregg Hart            -> Henry Stern          1374003 · 1392385 · 1435181 · 1477166
--   Dr. Corey A. Jackson  -> Thomas Umberg        1415628 · 1461222 · 1461225 · 1485168
--   Jasmeet Kaur Bains    -> Maria Elena Durazo   1428498
--
-- 🟢 The UNIQUE index `idx_politician_source_system_extid` cannot block these: measured on prod
-- 2026-10-11, all four real people are LIVE rows holding ZERO `cal_access` sources.
--
-- 🔴 **CONFIRMING THESE IS NOT A NO-OP, AND THE WORKLIST'S "ALL 19 CARRY $0" IS INCOMPLETE.**
-- $0 is true of our corpus TODAY. `campaignFinanceScheduler.ts` selects
-- `research_status = 'confirmed'` with NO source_type filter, and all 448 confirmed `cal_access`
-- candidate committees on prod have a completed ingestion run — none has no run at all. So
-- confirming these nine QUEUES them, and CAL-ACCESS holds real money for them (STERN FOR SENATE
-- 2024 alone reports $388,174.70 raised in 2024). ▶ Expect three sitting senators to move from
-- no finance data, through `data_pending`, to real dollars. That is the correct outcome and it
-- is stated here so nobody meets it as a surprise.
--
--
-- ══ ⚠ THE 3 THAT ARE OUTSIDE SPENDING, AND WHY THEY ARE WITHHELD ═════════════════════════════
--
-- A committee ABSENT from the candidate's own page is not candidate-controlled, whatever its
-- name says (`CC_0216`, the Hurtado reversal). These three name the person and are absent:
--
--   1385335  STERN STATE SENATE 2016; CALIFORNIANS IN SUPPORT OF HENRY   -> Henry Stern
--   1463858  ARCHULETA FOR LA COUNTY DA 2024; SAFER LA COMMITTEE
--            SUPPORTING JUDGE DEBRA                                      -> Debra Archuleta
--   1235879  UMBERG, CONSUMERS FOR TOM                                   -> Thomas Umberg
--
-- They are repointed to the right person and typed `ie_committee`, but held at `not_applicable`.
-- `getOutsideSpendingForPolitician` has **no zero-amount filter**, so a `confirmed` row with no
-- ingested money publishes an outside-spending card reading $0 with no donors. `CC_0216` held
-- 1447993 for exactly this reason. Operator decision, 2026-10-11.
--
-- ⚠ **DIRECTION IS SET ON TWO OF THE THREE, NOT ALL THREE.** ADR 0008 requires direction to be
-- evidenced, never defaulted. `IN SUPPORT OF` and `SUPPORTING` are approved support wording;
-- **`FOR` is not** — it is the standard shape of a candidate's OWN committee name, which is the
-- `FRIENDS OF` trap recorded in `CC_0221`. So `1235879` keeps `support_oppose = NULL` and is
-- named here as owed a direction.
--
-- 🔴 **AND THIS CREATES A DEADLOCK WORTH NAMING.** The scheduler ingests `confirmed` rows only.
-- Held at `not_applicable`, these three are never ingested, so their money never arrives, so the
-- "it would publish $0" reason stays true for ever. ▶ The way out is to confirm them and accept
-- one ingestion cycle — one UPDATE, once somebody decides the empty window is acceptable.
--
--
-- ══ ❌ THE ONE THAT IS DISPROVED, NOT MERELY UNVERIFIED ══════════════════════════════════════
--
-- `1076598` is stored as `STERN FOR CITY COUNCIL - 99`. CAL-ACCESS registers it as
-- **`RE-ELECT STERN -- 2003`, under its own filer id 991016**, terminated 07/06/2004, phone
-- (310) 519-0553 — an area code and a treasurer that appear on none of Henry Stern's committees.
-- His first race of any kind is State Senate District 27 in 2016. ▶ It is a different Stern.
-- The row stays detached; only its note changes, because "disproved" and "unverified" are
-- different facts and the next pass should not re-open it.
--
--
-- ══ ⚠ THE 4 THAT COULD NOT BE SETTLED — LEFT DETACHED, DELIBERATELY ══════════════════════════
--
--   1442984 / 1442999  STERN FOR SUPERVISOR 2022 (+ its attorney's fees fund)
--   1479450 / 1480690  both registered literally `DURAZO, MARIA ELENA`
--
-- Neither CAL-ACCESS instrument reaches them. They are absent from the candidate pages, and
-- **none of the four has an electronic filing**, so the Form 460 cover page Part 5 — the document
-- that names candidate and office under oath — does not exist to read. 🔴 That "no filings"
-- reading was CONTROLLED: the identical fetch against 1435181, 1458805, 1415628 and 1480691
-- returns full summary data and no such message, so it is a real reading and not a broken
-- detector. `la_socrata`, which covers LA County, holds no row for any of the four either.
--
-- ⚠ The Durazo pair is the close call and is left on the honest side. Its case is strong — the
-- committee's registered name IS her exact full name, which no surname-matcher failure mode can
-- produce; the treasurer matches all five of her confirmed committees; 1480690 is ADJACENT to
-- 1480691, which is on her page; both are ACTIVE in her cycle. But the bar this programme set is
-- the candidate page or Part 5, and neither answers. They carry $0, so holding costs nothing.
-- Operator decision, 2026-10-11.
--
--
-- ══ 🔴🔴 THE BLOCKER THIS MIGRATION HAD TO SETTLE: THE PLACEHOLDER ROWS ══════════════════════
--
-- Every one of these committees ALSO exists as its own "politician" — an inactive
-- `essentials.politicians` row whose `full_name` IS the committee name, holding the same
-- `external_id` at `needs_research`. **And most are DUPLICATED, two rows per committee.**
-- Measured on prod 2026-10-11: 26 such source rows across 16 of the 19 committees.
--
-- ▶ A bare repoint would therefore leave a second, identical attribution behind on a junk row —
-- which is the `CC_0220` hazard waiting for the dedupe merge to fire it. So the 19 placeholders
-- belonging to the 12 committees this migration adjudicates are set `not_applicable` and told
-- who the real owner is. The junk `politicians` rows themselves are NOT touched: that is
-- `.planning/todos/2026-07-03-cal-access-committee-rows-in-politicians.md`, 24,044 rows wide,
-- and a separate programme. The 7 placeholders of the disproved and unsettled committees are
-- left alone — there is no owner to name.
--
--
-- ══ CONTROLS ═════════════════════════════════════════════════════════════════════════════════
--
-- 🟢 The $0 claim is controlled. The identical contributions join over 1349095 / 1418587 /
--    1448127 returns 446 / 402 / 8 rows, so the zero on these 19 is a reading, not a dead join.
-- 🟢 The pre-verify gate is tamper-tested: drop one row from `_work` and it must fail at 18.
--
-- ⚠ `politician_sources.notes` is TEXT whose house convention appends prose after the JSON with
-- ` | `. The `adjudicated_by` key the CI attribution ratchet looks for must go INSIDE the JSON
-- object, so every write below merges it into the parsed prefix and re-attaches the tail. A bare
-- `notes::jsonb` raises 22P02 and took the finance endpoint down on 2026-10-10 (PR #979).

BEGIN;

DO $$
DECLARE
  v_cnt      int;
  v_contrib  bigint;
  n          int;
  STERN      uuid := 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6';
  UMBERG     uuid := '712be98b-a05d-4605-9603-cd5d86abfad1';
  DURAZO     uuid := 'c7dc9c50-84c6-4bde-af06-e7f9d5167e93';
  ARCHULETA  uuid := 'aa799786-0934-4d5e-a4ba-78ae984d7650';
  HART       uuid := '21940b7c-2424-47e9-a649-077b0f827c2c';
  JACKSON    uuid := 'bbd7825a-6778-4cca-81c8-8ef3ded55965';
  BAINS      uuid := '539874fc-489f-4643-9b1a-923aca6cc2c1';
  CHEN       uuid := 'ed32efa5-b455-4323-a12f-5fe79bc4ffd6';
BEGIN

  -- ── THE WORKLIST ──────────────────────────────────────────────────────────────────────────
  -- Keyed on (from_pid, 'cal_access', ext) — the same triple as the UNIQUE index and as the
  -- attribution baseline. Never on the row id: CC_0216/CC_0218 moved sources keeping their ids.

  CREATE TEMP TABLE _work (
    ext        text primary key,
    from_pid   uuid not null,
    to_pid     uuid,          -- NULL = stays where it is
    action     text not null, -- reattach | outside | disproved | unsettled
    direction  text           -- support_oppose, only for 'outside'
  ) ON COMMIT DROP;

  INSERT INTO _work VALUES
    -- ✅ on the candidate page, by filer id
    ('1374003', HART,    STERN,     'reattach', NULL),
    ('1392385', HART,    STERN,     'reattach', NULL),
    ('1435181', HART,    STERN,     'reattach', NULL),
    ('1477166', HART,    STERN,     'reattach', NULL),
    ('1415628', JACKSON, UMBERG,    'reattach', NULL),
    ('1461222', JACKSON, UMBERG,    'reattach', NULL),
    ('1461225', JACKSON, UMBERG,    'reattach', NULL),
    ('1485168', JACKSON, UMBERG,    'reattach', NULL),
    ('1428498', BAINS,   DURAZO,    'reattach', NULL),
    -- ⚠ names the person, absent from their page => outside spending, withheld
    ('1385335', HART,    STERN,     'outside',  'support'),
    ('1463858', CHEN,    ARCHULETA, 'outside',  'support'),
    ('1235879', JACKSON, UMBERG,    'outside',  NULL),
    -- ❌ disproved: a different Stern
    ('1076598', HART,    NULL,      'disproved', NULL),
    -- ⚠ unsettled: no candidate page, no electronic filing, no la_socrata row
    ('1442984', HART,    NULL,      'unsettled', NULL),
    ('1442999', HART,    NULL,      'unsettled', NULL),
    ('1479450', BAINS,   NULL,      'unsettled', NULL),
    ('1480690', BAINS,   NULL,      'unsettled', NULL);

  CREATE TEMP TABLE _rows ON COMMIT DROP AS
    SELECT s.id, w.ext, w.to_pid, w.action, w.direction
      FROM _work w
      JOIN transparent_motivations.politician_sources s
        ON s.source_system = 'cal_access'
       AND s.external_id = w.ext
       AND s.essentials_politician_id = w.from_pid;

  -- The placeholder rows of the 12 committees this migration gives an owner to.
  CREATE TEMP TABLE _placeholders ON COMMIT DROP AS
    SELECT s.id, w.ext, w.to_pid
      FROM _work w
      JOIN transparent_motivations.politician_sources s
        ON s.source_system = 'cal_access' AND s.external_id = w.ext
      JOIN essentials.politicians p ON p.id = s.essentials_politician_id
     WHERE w.action IN ('reattach','outside')
       AND NOT p.is_active;

  ANALYZE _rows;
  ANALYZE _placeholders;

  -- ── PRE-VERIFY ────────────────────────────────────────────────────────────────────────────

  SELECT count(*) INTO v_cnt FROM _work;
  IF v_cnt <> 17 THEN RAISE EXCEPTION 'CC_0230: worklist is %, expected 17 (19 less the 2 Valladares)', v_cnt; END IF;

  -- 🔴 Every worklist entry must resolve to EXACTLY one source row. external_id is not unique.
  SELECT count(*) INTO v_cnt FROM _rows;
  IF v_cnt <> 17 THEN RAISE EXCEPTION 'CC_0230: matched % source rows, expected 17', v_cnt; END IF;

  -- Each must currently be where CC_0223 left it: not_applicable on the WRONG live politician.
  SELECT count(*) INTO v_cnt
    FROM _rows r JOIN transparent_motivations.politician_sources s ON s.id = r.id
   WHERE s.research_status <> 'not_applicable';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0230: % rows are not not_applicable — CC_0223 state has moved, re-audit', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt
    FROM _rows r JOIN transparent_motivations.politician_sources s ON s.id = r.id
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE NOT p.is_active;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0230: % rows no longer sit on a LIVE politician', v_cnt; END IF;

  -- 🟢 The four targets must be live and must hold NO cal_access source, or the repoint collides
  -- with idx_politician_source_system_extid.
  SELECT count(*) INTO v_cnt FROM essentials.politicians p
   WHERE p.id IN (STERN, UMBERG, DURAZO, ARCHULETA) AND p.is_active;
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'CC_0230: % of the 4 targets are live, expected 4', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access'
     AND s.essentials_politician_id IN (STERN, UMBERG, DURAZO, ARCHULETA);
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0230: the targets already hold % cal_access sources — the repoint would collide', v_cnt;
  END IF;

  -- 🔴 Nothing here may move money. Controlled: the same join over 1349095/1418587/1448127
  -- returns 446/402/8, so a zero here is a reading and not a dead join.
  -- ⚠ `= ANY(ARRAY(...))` and the ANALYZE above are both load-bearing: a plain JOIN to an
  -- un-analysed temp table makes the planner seq-scan `contributions` and the statement TIMES OUT.
  SELECT count(*) INTO v_contrib
    FROM transparent_motivations.contributions c
   WHERE c.politician_source_id = ANY (ARRAY(SELECT id FROM _rows));
  IF v_contrib <> 0 THEN
    RAISE EXCEPTION 'CC_0230: the 17 sources carry % contributions, expected 0 — refusing', v_contrib;
  END IF;

  SELECT count(*) INTO v_cnt FROM _placeholders;
  IF v_cnt <> 19 THEN RAISE EXCEPTION 'CC_0230: % placeholder rows, expected 19', v_cnt; END IF;

  -- A placeholder must be exactly that: an inactive row whose full_name IS a committee name,
  -- never a real person caught by the external_id.
  SELECT count(*) INTO v_cnt
    FROM _placeholders x JOIN transparent_motivations.politician_sources s ON s.id = x.id
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE p.source <> 'cal_access_discovery';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0230: % placeholder rows are not cal_access_discovery — read them first', v_cnt;
  END IF;

  -- ── CHANGE 1: the 9 the candidate page carries ────────────────────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET essentials_politician_id = r.to_pid,
         research_status = 'confirmed',
         notes = (CASE
                    WHEN s.notes IS JSON OBJECT
                      THEN (s.notes::jsonb || '{"adjudicated_by":"CC_0230"}'::jsonb)::text
                    WHEN left(s.notes, strpos(s.notes, '} |')) IS JSON OBJECT
                      THEN (left(s.notes, strpos(s.notes, '} |'))::jsonb
                            || '{"adjudicated_by":"CC_0230"}'::jsonb)::text
                           || substr(s.notes, strpos(s.notes, '} |') + 1)
                    ELSE COALESCE(s.notes, '')
                  END)
                 || ' | RE-ATTACHED CC_0230 (2026-10-11): this committee is listed by filer id on '
                 || 'its real owner''s CAL-ACCESS CANDIDATE page, which names the candidate AND the '
                 || 'committee together — the only primary source that settles a California finance '
                 || 'attribution. CC_0223 detached it from a live politician it never belonged to; '
                 || 'this is the evidenced re-attachment that note promised.',
         updated_at = now()
    FROM _rows r
   WHERE s.id = r.id AND r.action = 'reattach';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 9 THEN RAISE EXCEPTION 'CC_0230: re-attached % rows, expected 9', n; END IF;

  -- ── CHANGE 2: the 3 outside-spending committees — repointed, typed, withheld ───────────────

  UPDATE transparent_motivations.politician_sources s
     SET essentials_politician_id = r.to_pid,
         source_type = 'ie_committee',
         support_oppose = r.direction,
         research_status = 'not_applicable',
         notes = COALESCE(s.notes, '')
                 || ' | OUTSIDE SPENDING CC_0230 (2026-10-11): this committee names the politician '
                 || 'but is ABSENT from their CAL-ACCESS candidate page, so it is not candidate-'
                 || 'controlled (CC_0216, the Hurtado reversal). Repointed to the right person and '
                 || 'typed ie_committee. HELD at not_applicable because '
                 || 'getOutsideSpendingForPolitician has no zero-amount filter and our corpus holds '
                 || '$0 for it, so confirming it would publish a card reading $0 with no donors. '
                 || '⚠ The scheduler ingests confirmed rows only, so holding it is also what keeps '
                 || 'it at $0 — confirming it is one UPDATE whenever the empty window is acceptable.',
         updated_at = now()
    FROM _rows r
   WHERE s.id = r.id AND r.action = 'outside';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 3 THEN RAISE EXCEPTION 'CC_0230: repointed % outside-spending rows, expected 3', n; END IF;

  -- ── CHANGE 3: the one that is disproved, not merely unverified ─────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET notes = COALESCE(s.notes, '')
                 || ' | DISPROVED CC_0230 (2026-10-11): stays detached, and the reason is now '
                 || 'POSITIVE rather than an absence of evidence. CAL-ACCESS registers 1076598 as '
                 || '"RE-ELECT STERN -- 2003" under its own filer id 991016, terminated 07/06/2004, '
                 || 'phone (310) 519-0553 — a treasurer and area code on none of Henry Stern''s '
                 || 'committees, and it is absent from his candidate page. His first race of any '
                 || 'kind is State Senate District 27 in 2016. It is a different Stern. Do not '
                 || 're-open this row.',
         updated_at = now()
    FROM _rows r
   WHERE s.id = r.id AND r.action = 'disproved';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0230: marked % disproved, expected 1', n; END IF;

  -- ── CHANGE 4: the 4 that could not be settled — record the closed route, change nothing else ─

  UPDATE transparent_motivations.politician_sources s
     SET notes = COALESCE(s.notes, '')
                 || ' | UNSETTLED CC_0230 (2026-10-11): left detached on purpose. The evidence route '
                 || 'was tried and is closed — absent from the candidate page, NO electronic filing '
                 || 'so no Form 460 cover page Part 5 exists to read (controlled: the same fetch '
                 || 'against 1435181/1458805/1415628/1480691 returns full summary data), and '
                 || 'la_socrata holds no row for it either. ⚠ A candidate page race history covers '
                 || 'STATE races only, so its silence on a county race proves nothing. Carries $0. '
                 || 'Settling it needs a document that names the person.',
         updated_at = now()
    FROM _rows r
   WHERE s.id = r.id AND r.action = 'unsettled';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 4 THEN RAISE EXCEPTION 'CC_0230: marked % unsettled, expected 4', n; END IF;

  -- ── CHANGE 5: the placeholder rows — the CC_0220 hazard, closed ───────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET research_status = 'not_applicable',
         notes = COALESCE(s.notes, '')
                 || ' | NOT APPLICABLE CC_0230 (2026-10-11): this row is not a person. It is the '
                 || 'committee''s own cal_access_discovery placeholder — an inactive politicians row '
                 || 'whose full_name IS the committee name — and most such committees carry two of '
                 || 'them. CC_0230 gave this committee its evidenced owner, so the placeholder is '
                 || 'detached to stop a later dedupe merge carrying it onto a live officeholder, '
                 || 'which is the CC_0220 incident. The junk politicians row itself is left for '
                 || '.planning/todos/2026-07-03-cal-access-committee-rows-in-politicians.md.',
         updated_at = now()
    FROM _placeholders x
   WHERE s.id = x.id AND s.research_status <> 'not_applicable';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 19 THEN RAISE EXCEPTION 'CC_0230: detached % placeholders, expected 19', n; END IF;

  -- ── POST-VERIFY ───────────────────────────────────────────────────────────────────────────

  -- The 9 landed on the right people, confirmed, as candidate committees.
  SELECT count(*) INTO v_cnt
    FROM _rows r JOIN transparent_motivations.politician_sources s ON s.id = r.id
   WHERE r.action = 'reattach'
     AND s.essentials_politician_id = r.to_pid
     AND s.research_status = 'confirmed'
     AND s.source_type = 'candidate_committee';
  IF v_cnt <> 9 THEN RAISE EXCEPTION 'CC_0230: % of the 9 landed correctly, expected 9', v_cnt; END IF;

  -- Per-target split, so a repoint cannot land them all on one person and still pass.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = STERN AND s.source_system = 'cal_access'
     AND s.research_status = 'confirmed';
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'CC_0230: Stern holds % confirmed, expected 4', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = UMBERG AND s.source_system = 'cal_access'
     AND s.research_status = 'confirmed';
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'CC_0230: Umberg holds % confirmed, expected 4', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = DURAZO AND s.source_system = 'cal_access'
     AND s.research_status = 'confirmed';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0230: Durazo holds % confirmed, expected 1', v_cnt; END IF;

  -- 🔴 Nothing may PUBLISH from the outside-spending three: the read path needs confirmed AND a
  -- direction. Assert both halves, so setting a direction later cannot silently publish them.
  SELECT count(*) INTO v_cnt
    FROM _rows r JOIN transparent_motivations.politician_sources s ON s.id = r.id
   WHERE r.action = 'outside'
     AND s.source_type = 'ie_committee'
     AND s.research_status = 'not_applicable'
     AND s.essentials_politician_id = r.to_pid;
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'CC_0230: % outside rows landed correctly, expected 3', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM _rows r JOIN transparent_motivations.politician_sources s ON s.id = r.id
   WHERE r.action = 'outside' AND s.support_oppose IS NOT NULL;
  IF v_cnt <> 2 THEN
    RAISE EXCEPTION 'CC_0230: % outside rows carry a direction, expected 2 (1235879 is owed one)', v_cnt;
  END IF;

  -- The CI attribution ratchet: every NEWLY confirmed row must name who adjudicated it.
  SELECT count(*) INTO v_cnt
    FROM _rows r JOIN transparent_motivations.politician_sources s ON s.id = r.id
   WHERE r.action = 'reattach' AND s.notes !~ '"adjudicated_by"\s*:';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0230: % confirmed rows carry no adjudicated_by — check:cal-access-attribution will fail', v_cnt;
  END IF;

  -- ⚠ And the notes must still PARSE, or the finance endpoint 500s (PR #979).
  SELECT count(*) INTO v_cnt
    FROM _rows r JOIN transparent_motivations.politician_sources s ON s.id = r.id
   WHERE (CASE
            WHEN s.notes IS JSON OBJECT THEN s.notes::jsonb
            WHEN left(s.notes, strpos(s.notes, '} |')) IS JSON OBJECT
              THEN left(s.notes, strpos(s.notes, '} |'))::jsonb
          END) IS NULL;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0230: % rows no longer parse as notes-JSON', v_cnt; END IF;

  -- No placeholder is left publishing, and none of the 4 unsettled moved.
  SELECT count(*) INTO v_cnt
    FROM _placeholders x JOIN transparent_motivations.politician_sources s ON s.id = x.id
   WHERE s.research_status <> 'not_applicable';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0230: % placeholders still publish', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM _rows r JOIN transparent_motivations.politician_sources s ON s.id = r.id
   WHERE r.action IN ('unsettled','disproved')
     AND (s.research_status <> 'not_applicable'
          OR s.essentials_politician_id NOT IN (HART, BAINS));
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0230: % held rows moved — they must not', v_cnt; END IF;

  -- Still no money anywhere in the slice.
  SELECT count(*) INTO v_contrib
    FROM transparent_motivations.contributions c
   WHERE c.politician_source_id = ANY (ARRAY(SELECT id FROM _rows));
  IF v_contrib <> 0 THEN RAISE EXCEPTION 'CC_0230: the slice now carries % contributions', v_contrib; END IF;

  -- The disputed population is untouched: this migration adjudicates not_applicable rows only.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 365 THEN
    RAISE EXCEPTION 'CC_0230: % cal_access sources disputed, expected 365 unchanged', v_cnt;
  END IF;

  RAISE NOTICE 'CC_0230 OK — 9 re-attached and confirmed, 3 outside-spending withheld, 1 disproved, 4 unsettled, 19 placeholders detached.';
END $$;

COMMIT;
