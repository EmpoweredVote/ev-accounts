-- CC_0216 — adjudicate the 72 disputed CAL-ACCESS bucket sources left by CC_0213 / CC_0214.
--
-- `CC_0213` detached 159 CAL-ACCESS sources from seven surname buckets, and `CC_0214` returned the
-- eight that named their owner in full. Three bucket rows were deliberately KEPT rather than
-- retired, because they still held disputed money nobody had ruled on:
--
--     Arthur Dixon    b8e3727a   43 disputed
--     Gil Hurtado     1a6190c0   15 disputed
--     Fernando Dutra  bf91e362   14 disputed
--                                ── 72
--
-- All three rows are `is_active = false`, so none of this is visible to a voter today. The question
-- this migration answers is the one CC_0214 left open: **whose money is each of the 72?**
-- Worklist and evidence: `.planning/todos/2026-10-09-finance-surname-buckets.md`.
--
-- The answer is 10 and 62. Ten belong to a politician we already hold. Sixty-two belong to people
-- who have no row in this corpus, so there is nowhere for them to go and nothing to publish.
--
--
-- ══ PART 1 — TEN SOURCES GO TO THEIR REAL OWNER ══════════════════════════════════════════════
--
-- **Diane B. Dixon** `9aa10096` — California Assembly Member, AD-72, ACTIVE, and holding
-- **zero finance sources** until this migration. Eight of Arthur Dixon's 43 are hers.
--
-- 🟢 **SEVEN ARE NAMED BY CAL-ACCESS ITSELF.** The Secretary of State's candidate detail page for
-- `DIXON, DIANE` (candidate filer **1418515**) lists each one under "Candidates manage their
-- campaign funds through their campaign committees". That is a primary source naming the committee
-- AND the candidate — not a surname match, and not an inference from the committee title.
--
--     1418525  DIXON FOR ASSEMBLY 2020             944   $979,996.68
--     1456771  DIXON FOR ASSEMBLY 2024             621   $923,509.29
--     1443172  DIXON FOR ASSEMBLY 2022; DIANE      618   $704,981.22
--     1438441  DIXON FOR SUPERVISOR 2022; DIANE    222   $175,649.49
--     1477047  DIXON FOR ASSEMBLY 2026; DIANE       88   $188,184.56
--     1435365  DIXON FOR ASSEMBLY 2022              32   $  9,649.00
--     1362246  DIXON FOR CITY COUNCIL, DIANE         6   $  2,300.00
--
-- ⚠ Three of those seven carry **no forename at all** in the committee name. That is exactly the
-- false trail the worklist records: "the forename is absent" convicts nobody and acquits nobody.
-- The candidate page is what settles them, and it settles them regardless of the title.
--
-- 🔴 **THE EIGHTH IS NOT ON THAT PAGE AND WAS MEASURED SEPARATELY**:
--
--     1480126  DIXON FOR SUPERVISOR 2026; DIANE    791   $798,783.92
--
--   Three independent signals, all agreeing, none of them a surname match:
--     1. The committee name carries the explicit forename DIANE. No conflicting forename exists.
--     2. Its CAL-ACCESS **filer phone is (949) 858-7448 — byte-identical to 1438441**, which the
--        candidate page DOES confirm as hers, and which is the same office one cycle earlier.
--     3. Donor-name overlap, with controls. Of its 583 distinct donors, her seven confirmed
--        committees share **12.4% – 62.8%** (the nearest in time, ASSEMBLY 2026, shares 62.8%).
--        Unrelated CAL-ACCESS committees in the same buckets share **0.0% – 4.4%**
--        (Hurtado 4.4%, Dutra 1.4% / 0.6%). A 3x–14x separation, measured, not eyeballed.
--
--   ⚠ The overlap query is worth re-reading before reusing: `contributions.donor_id` is NULL on
--   every CAL-ACCESS row here, and the first attempt joined on it and returned a UNIFORM ZERO for
--   all nine committees. A uniform answer is a broken detector. `donor_name_normalized` is the
--   populated column, and the controls are what proved the rewritten query could discriminate.
--
-- **Melissa Hurtado** `d3b4ee4d` — California State Senator, ACTIVE, 5 sources and 1,577
-- contributions after CC_0213. Two of Gil Hurtado's 15 concern her, and they are NOT the same case:
--
--     1456951  HURTADO FOR SENATE 2026; VALLEY FAMILIES FOR MELISSA   467   $3,431,362.52
--     1447993  HURTADO 2022; COALITION OF BUSINESS ORGS … MELISSA       8   $  344,843.80
--
-- 🔴🔴 **CC_0213 WAS WRONG ABOUT 1456951, AND THIS REVERSES IT.** That migration held both back,
-- reading both as independent-expenditure committees, and said their `source_type` "needs a human
-- ruling". The ruling is available from the same primary source used for Dixon: CAL-ACCESS lists
-- **"VALLEY FAMILIES FOR MELISSA HURTADO FOR SENATE 2026" (ID# 1456951) on her own candidate page**
-- (filer 1401463), beside HURTADO FOR SENATE 2022 and HURTADO FOR SENATE 2018. It is her
-- **controlled committee**, not outside spending, and it is restored to `confirmed`.
-- ▶ A committee whose name reads like a support group can still be the candidate's own. The
--   candidate page answers it; the title does not.
--   (Its $3.43M is mostly party transfers — ENTITY_CD 'PTY': California Democratic Party $400,000,
--   then county central committees at $100,000 each. Normal for a 2026 Senate campaign.)
--
-- 1447993 is the opposite: it is **absent** from her candidate page, and its full registered name is
-- "COALITION OF BUSINESS ORGANIZATIONS SUPPORTING SENATOR MELISSA HURTADO 2022". It is genuine
-- outside spending in her race. It moves to her row and is retyped `ie_committee`.
--
-- 🔴 **BUT IT IS DELIBERATELY NOT SET `confirmed`, AND THAT IS NOT CAUTION — IT IS A MEASURED
-- DISPLAY BUG.** `getOutsideSpendingForPolitician` (`campaignFinanceService.ts`) scopes its
-- `ie_all_sources` CTE to **`ps.source_system = 'la_socrata'`** and reads the committee label from
-- **`notes::jsonb->>'cmt_nm'`**, a key CAL-ACCESS notes do not carry. A `confirmed` cal_access
-- `ie_committee` row would therefore render on her page as an **unnamed committee card showing $0**
-- — the committee list CTE has no source_system filter, but the totals join does. So the row is
-- recorded at `not_applicable`, which publishes nothing, and one UPDATE turns it on once that
-- function is widened. Operator ruling 2026-10-09: record it, do not publish it.
--
--
-- ══ PART 2 — SIXTY-TWO HAVE NO OWNER IN THIS CORPUS ══════════════════════════════════════════
--
-- Operator ruling 2026-10-09: these become **`not_applicable`**, not `disputed`.
-- `disputed` reads as "contested and unresolved" and would invite the next session to redo this
-- research; `not_applicable` says it was adjudicated and the committee is not this person's.
-- `backend/src/lib/adapters/indianaAdapter.ts:772` treats the two identically ("the wrong committee,
-- and their rows are dropped"), and every finance read filters on `confirmed`, so no voter-facing
-- value changes. The difference is that the record now says the work was done.
--
--     Arthur Dixon    35   ~24 are candidates in the CITY of Dixon, California — Arnold, Batchelor,
--                          Bird, Bogue, Castanon, Ceremello, Di Paola, Dingman, Fink, Graham,
--                          Hendershot, Janisch, McCaffrey, McCluskey, Minnema, Swanson, Thiessen,
--                          Young. 🟢 **We hold no government named Dixon**, so not one of them can
--                          be in this corpus — the whole slice is settled by a single query. The
--                          rest are Julian, Rich, Linda, Richard, Fredrisha, Ken, Karen L. and
--                          Ronda Dixon. Only Ronda's (21 contributions) and DIXON FOR JUDGE 2026
--                          (3) hold money.
--     Gil Hurtado     13   Esmeralda, Jewel, G. Sylvia, Jaime and Ricky Hurtado. Esmeralda's 2026
--                          Senate committee holds 9 contributions; the other 12 hold none.
--     Fernando Dutra  14   John, Jimmy, Joe M., Dominic and Clancy Dutra. John Dutra's State Senate
--                          (1,631) and ASSEMBLY 2002 (352) committees hold all the money. He left
--                          the Assembly in 2004 and has no row here; CAL-ACCESS's "by name"
--                          candidate list no longer covers that session either.
--
-- 🔴 **THE THREE BUCKET ROWS STILL CANNOT BE RETIRED, AND THIS MIGRATION DOES NOT RETIRE THEM.**
-- CC_0214's rule stands: `politician_sources.essentials_politician_id` is NOT NULL and
-- `filed_report_summaries` holds a RESTRICT FK, so deleting a bucket row forces its 62 sources
-- either onto a live politician — re-creating the harm CC_0213 removed — or out of existence.
-- Adjudicating them does not change that; it only means nobody needs to adjudicate them again.
-- An inactive row publishes nothing, so the delete still buys nothing.
--
-- ⚠ **THE SAME `external_id` SITS ON SEVERAL POLITICIAN ROWS**, as CC_0213 recorded — including
-- rows in `essentials.politicians` whose `full_name` IS A COMMITTEE NAME ("DIXON FOR ASSEMBLY 2020",
-- inactive, `needs_research`, sometimes two of them for one filer). Every statement below resolves
-- a source by (external_id + the bucket row it currently hangs on), never by external_id alone.
-- Those placeholder rows are out of scope here and are left untouched.

BEGIN;

DO $$
DECLARE
  r           record;
  n_point     int := 0;
  n_na        int := 0;
  v_cnt       bigint;
  v_n         bigint;
  v_contrib0  bigint;
  v_sum       numeric;
  v_sid       uuid;
  v_diane     uuid;
  v_melissa   uuid;
BEGIN
  -- ── idempotence: if Diane already holds her eight, this has run. Do nothing, say so.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE p.id::text LIKE '9aa10096%' AND s.source_system = 'cal_access';
  IF v_cnt = 8 THEN
    RAISE NOTICE 'CC_0216: already applied (Diane B. Dixon holds 8 cal_access sources) — skipping';
    RETURN;
  END IF;

  -- ── resolve the three bucket rows by id prefix, so no mistyped uuid can reach a live page
  CREATE TEMP TABLE _buckets ON COMMIT DROP AS
    SELECT p.id, p.full_name
      FROM essentials.politicians p
     WHERE p.id::text LIKE 'b8e3727a%' OR p.id::text LIKE '1a6190c0%' OR p.id::text LIKE 'bf91e362%';

  SELECT count(*) INTO v_cnt FROM _buckets;
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'CC_0216: resolved % bucket rows, expected 3', v_cnt; END IF;

  -- a bucket row must be inactive; adjudicating sources off a LIVE page is a different decision
  SELECT count(*) INTO v_cnt
    FROM _buckets b JOIN essentials.politicians p ON p.id = b.id WHERE p.is_active;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0216: % bucket rows are ACTIVE — refusing', v_cnt; END IF;

  -- the 72 must be there, all cal_access, all disputed, all with parseable notes
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _buckets b ON b.id = s.essentials_politician_id;
  IF v_cnt <> 72 THEN
    RAISE EXCEPTION 'CC_0216: bucket rows hold % sources, expected 72 — the buckets have changed', v_cnt;
  END IF;
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _buckets b ON b.id = s.essentials_politician_id
   WHERE s.source_system <> 'cal_access' OR s.research_status <> 'disputed' OR s.notes IS NULL;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0216: % of the 72 are not disputed cal_access sources with notes', v_cnt;
  END IF;

  -- hold the 72 source ids, so the "no contribution was touched" check below can be asked of
  -- exactly those rows. ⚠ Asking it of the whole `contributions` table exceeds the statement
  -- timeout on prod — CC_0213 recorded that trap for a `NOT EXISTS` over the same table.
  CREATE TEMP TABLE _srcs ON COMMIT DROP AS
    SELECT s.id FROM transparent_motivations.politician_sources s
      JOIN _buckets b ON b.id = s.essentials_politician_id;

  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);

  -- ── resolve the two owners, by id prefix AND by name AND by being live
  SELECT p.id INTO v_diane FROM essentials.politicians p
   WHERE p.id::text LIKE '9aa10096%' AND p.full_name = 'Diane B. Dixon' AND p.is_active;
  IF v_diane IS NULL THEN RAISE EXCEPTION 'CC_0216: no active "Diane B. Dixon" at 9aa10096 — refusing'; END IF;

  SELECT p.id INTO v_melissa FROM essentials.politicians p
   WHERE p.id::text LIKE 'd3b4ee4d%' AND p.full_name = 'Melissa Hurtado' AND p.is_active;
  IF v_melissa IS NULL THEN RAISE EXCEPTION 'CC_0216: no active "Melissa Hurtado" at d3b4ee4d — refusing'; END IF;

  -- Diane must hold the seat the evidence rests on. CAL-ACCESS ties filer 1418515 to the AD-72
  -- officeholder; if our row is not an Assembly Member, the identity chain is broken and we stop.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
     WHERE t.politician_id = v_diane AND o.title = 'Assembly Member'
  ) THEN
    RAISE EXCEPTION 'CC_0216: Diane B. Dixon holds no Assembly Member term — refusing to publish her finance';
  END IF;

  -- ── PART 1: the ten repoints. Nine publish; 1447993 is recorded without publishing.
  FOR r IN
    SELECT x.ext, x.bucket_like, x.owner, x.stype, x.status, x.why
      FROM (VALUES
        ('1418525','b8e3727a%','diane',  'candidate_committee','confirmed',
         'CAL-ACCESS candidate page for DIXON, DIANE (filer 1418515) lists this committee'),
        ('1456771','b8e3727a%','diane',  'candidate_committee','confirmed',
         'CAL-ACCESS candidate page for DIXON, DIANE (filer 1418515) lists this committee'),
        ('1443172','b8e3727a%','diane',  'candidate_committee','confirmed',
         'CAL-ACCESS candidate page for DIXON, DIANE (filer 1418515) lists this committee'),
        ('1438441','b8e3727a%','diane',  'candidate_committee','confirmed',
         'CAL-ACCESS candidate page for DIXON, DIANE (filer 1418515) lists this committee'),
        ('1477047','b8e3727a%','diane',  'candidate_committee','confirmed',
         'CAL-ACCESS candidate page for DIXON, DIANE (filer 1418515) lists this committee'),
        ('1435365','b8e3727a%','diane',  'candidate_committee','confirmed',
         'CAL-ACCESS candidate page for DIXON, DIANE (filer 1418515) lists this committee'),
        ('1362246','b8e3727a%','diane',  'candidate_committee','confirmed',
         'CAL-ACCESS candidate page for DIXON, DIANE (filer 1418515) lists this committee'),
        ('1480126','b8e3727a%','diane',  'candidate_committee','confirmed',
         'forename DIANE, filer phone (949) 858-7448 identical to her confirmed 1438441, and 12.4-62.8% donor overlap with her seven confirmed committees against 0.0-4.4% for controls'),
        ('1456951','1a6190c0%','melissa','candidate_committee','confirmed',
         'CAL-ACCESS candidate page for HURTADO, MELISSA (filer 1401463) lists this committee as hers — reverses CC_0213, which read it as an IE committee'),
        ('1447993','1a6190c0%','melissa','ie_committee',       'not_applicable',
         'genuine outside spending in her race (absent from her candidate page). Held at not_applicable only because getOutsideSpendingForPolitician scopes ie_all_sources to source_system=la_socrata and reads notes->cmt_nm; set confirmed once that is widened')
      ) AS x(ext, bucket_like, owner, stype, status, why)
  LOOP
    v_sid := CASE r.owner WHEN 'diane' THEN v_diane ELSE v_melissa END;

    -- exactly one source: this external_id as it hangs on THAT bucket row
    SELECT count(*) INTO v_cnt
      FROM transparent_motivations.politician_sources s
      JOIN _buckets b ON b.id = s.essentials_politician_id
     WHERE s.source_system = 'cal_access' AND s.external_id = r.ext AND b.id::text LIKE r.bucket_like;
    IF v_cnt <> 1 THEN
      RAISE EXCEPTION 'CC_0216: external_id % resolves to % sources on its bucket row, expected 1', r.ext, v_cnt;
    END IF;

    UPDATE transparent_motivations.politician_sources s
       SET essentials_politician_id = v_sid,
           research_status          = r.status,
           source_type              = r.stype,
           notes                    = (s.notes::jsonb
                                        || jsonb_build_object('adjudicated_by','CC_0216',
                                                              'adjudication', r.why))::text,
           updated_at               = now()
     WHERE s.source_system = 'cal_access' AND s.external_id = r.ext
       AND s.essentials_politician_id IN (SELECT id FROM _buckets WHERE id::text LIKE r.bucket_like);
    n_point := n_point + 1;
  END LOOP;

  IF n_point <> 10 THEN RAISE EXCEPTION 'CC_0216: repointed % sources, expected 10', n_point; END IF;

  -- ── PART 2: everything still on a bucket row has no owner in this corpus
  WITH moved AS (
    UPDATE transparent_motivations.politician_sources s
       SET research_status = 'not_applicable',
           notes           = (s.notes::jsonb
                               || jsonb_build_object('adjudicated_by','CC_0216',
                                                     'adjudication',
                                                     'committee belongs to a person with no row in this corpus'))::text,
           updated_at      = now()
      FROM _buckets b
     WHERE s.essentials_politician_id = b.id
       AND s.source_system = 'cal_access'
       AND s.research_status = 'disputed'
    RETURNING 1)
  SELECT count(*) INTO v_cnt FROM moved;
  n_na := v_cnt::int;

  IF n_na <> 62 THEN
    RAISE EXCEPTION 'CC_0216: marked % sources not_applicable, expected 62', n_na;
  END IF;

  -- ══ POST-VERIFY ═════════════════════════════════════════════════════════════════════════════

  -- 1. No bucket row may publish anything. Unlike CC_0213 — where Erickson legitimately kept his
  --    own money — these three rows are pure buckets, so zero is the correct assertion here.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
    JOIN _buckets b ON b.id = s.essentials_politician_id
   WHERE s.research_status = 'confirmed' AND s.source_type = 'candidate_committee';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0216: bucket rows still publish % contributions', v_cnt;
  END IF;

  -- 2. Nothing disputed may remain on a bucket row — that was the whole job.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _buckets b ON b.id = s.essentials_politician_id
   WHERE s.research_status = 'disputed';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0216: % disputed sources remain on the bucket rows', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _buckets b ON b.id = s.essentials_politician_id;
  IF v_cnt <> 62 THEN RAISE EXCEPTION 'CC_0216: bucket rows hold % sources, expected 62', v_cnt; END IF;

  -- 3. 🔴 THE GUARD THAT MATTERS: no non-confirmed source may reach a LIVE politician's own
  --    fundraising, and no source may reach a live row without having been adjudicated here.
  --    This is the control CC_0214 planted a tamper against; it is kept.
  --    ⚠ Scoped to the 72 by id. An earlier draft selected every cal_access source on every live
  --    politician and read `notes::jsonb->>'adjudicated_by'`; the dry run died with "invalid input
  --    syntax for type json", because notes elsewhere in the corpus are not all parseable. A guard
  --    must not depend on data it did not put there.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE s.id IN (SELECT id FROM _srcs)
     AND p.is_active
     AND NOT (s.research_status = 'confirmed' AND s.source_type = 'candidate_committee')
     AND NOT (s.research_status = 'not_applicable' AND s.source_type = 'ie_committee');
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0216: % sources reached a LIVE politician in an unruled state', v_cnt;
  END IF;

  -- 4. Diane B. Dixon publishes exactly what the evidence bought: 8 committees, 3,322
  --    contributions, $3,783,054.16. She published NOTHING before this migration.
  SELECT count(DISTINCT s.id), count(c.id), coalesce(sum(c.amount), 0)
    INTO v_cnt, v_n, v_sum
    FROM transparent_motivations.politician_sources s
    LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.essentials_politician_id = v_diane
     AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee';
  IF v_cnt <> 8 THEN RAISE EXCEPTION 'CC_0216: Diane B. Dixon holds % confirmed committees, expected 8', v_cnt; END IF;
  IF v_n <> 3322 THEN RAISE EXCEPTION 'CC_0216: Diane B. Dixon publishes % contributions, expected 3322', v_n; END IF;
  IF round(v_sum, 2) <> 3783054.16 THEN
    RAISE EXCEPTION 'CC_0216: Diane B. Dixon publishes %, expected 3783054.16', round(v_sum, 2);
  END IF;

  -- 5. Melissa Hurtado gains 1456951 and nothing else: 6 committees, 2,044 contributions
  --    (1,577 from CC_0213 + 467), $11,894,567.23 ($8,463,204.71 + $3,431,362.52).
  SELECT count(DISTINCT s.id), count(c.id), coalesce(sum(c.amount), 0)
    INTO v_cnt, v_n, v_sum
    FROM transparent_motivations.politician_sources s
    LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.essentials_politician_id = v_melissa
     AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee';
  IF v_cnt <> 6 THEN RAISE EXCEPTION 'CC_0216: Melissa Hurtado holds % confirmed committees, expected 6', v_cnt; END IF;
  IF v_n <> 2044 THEN RAISE EXCEPTION 'CC_0216: Melissa Hurtado publishes % contributions, expected 2044', v_n; END IF;
  IF round(v_sum, 2) <> 11894567.23 THEN
    RAISE EXCEPTION 'CC_0216: Melissa Hurtado publishes %, expected 11894567.23', round(v_sum, 2);
  END IF;

  -- 6. The outside committee is on her row, typed, and publishing NOTHING.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = v_melissa AND s.external_id = '1447993'
     AND s.source_type = 'ie_committee' AND s.research_status = 'not_applicable';
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'CC_0216: 1447993 is not recorded as a non-publishing ie_committee on Melissa Hurtado';
  END IF;

  -- 7. No contribution row was touched, and none was stranded. The same 72 source ids still carry
  --    the same number of contributions — they moved with their source, as a repoint must.
  --    CC_0213 and CC_0214 moved none either; this is the invariant that keeps the whole sequence
  --    revertible with UPDATEs alone.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_cnt <> v_contrib0 THEN
    RAISE EXCEPTION 'CC_0216: the 72 sources carried % contributions and now carry % — rows were touched',
                    v_contrib0, v_cnt;
  END IF;

  RAISE NOTICE 'CC_0216: 10 sources repointed, 62 marked not_applicable, 0 contributions touched';
END $$;

COMMIT;
