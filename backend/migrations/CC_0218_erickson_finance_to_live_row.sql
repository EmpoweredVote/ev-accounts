-- CC_0218 — give John Erickson the campaign finance stranded on his scraped duplicate row.
--
-- `CC_0217` found that all four of its bucket rows are `source = 'scraped'` duplicates of a seated
-- official. This is the only one of them where money is involved, and it is the `CC_0211` shape with
-- one difference: **both rows publish**, so a voter sees a PARTIAL picture rather than none.
--
--     af66146f  John M. Erickson  INACTIVE, scraped   cal_access       $1,334,432.72 / 980 published
--     29ccd743  John Erickson     ACTIVE, Council Member, West Hollywood
--                                 la_county_netfile (WEHO)              $229,925.90 /  459+299
--
-- His 2026 State Senate campaign is on the archived row. His live page shows only council money.
--
-- 🔴 **THIS DOES NOT RETIRE THE SCRAPED ROW** (operator ruling 2026-10-09). Only the three earned
-- sources move; the 13 `not_applicable` orphans `CC_0217` adjudicated stay where they are. Reason:
-- retiring the row would force those 13 other Ericksons' committees onto a LIVE politician or out of
-- existence, and `contributions.politician_source_id` has **NO foreign key** — measured, only
-- `filed_report_summaries` references `politician_sources`, with RESTRICT — so deleting a source
-- silently STRANDS its contribution rows rather than failing. One of the 13 holds 323 of them.
-- ▶ Moving three sources fixes what a voter sees, reverts with one UPDATE, and leaves the
-- retirement available later. Retirement is tidiness; the attribution was the harm.
--
--
-- ══ IDENTITY — TWO SOURCES, AND THE OBVIOUS TEST DID NOT WORK ════════════════════════════════
--
-- ⚠ **CO-LOCATION ON THE BUCKET ROW IS NOT EVIDENCE.** `ERICKSON FOR WH CITY COUNCIL 2020; JOHN`
-- and `ERICKSON FOR STATE SENATE 2026; JOHN` sit on the same scraped row only because
-- `confirm-cal-access.ts` matched BY SURNAME. That the bucket put them together says nothing about
-- whether one man filed both — assuming otherwise is the exact defect this programme exists to undo.
--
-- 🔴🔴 **THE DONOR-OVERLAP TEST CAME BACK UNINFORMATIVE, NOT CONFIRMING, AND IT IS WORTH SAYING SO.**
-- It settled `DIXON FOR SUPERVISOR 2026` in `CC_0216`. Here, of the Senate committee's 617 distinct
-- donors, his OWN West Hollywood council committees share **1.6% and 0.7%** — inside the control
-- band (Hurtado's unrelated Senate committee scored **2.2%**, higher than either). Measured:
--
--     1456951  HURTADO FOR SENATE 2026 (control)        2.2%
--     210075987 ERICKSON WEHO COUNCIL 2024 (his own)    1.6%
--     185138647 ERICKSON WEHO COUNCIL      (his own)    0.7%
--     1393990  PATTERSON FOR ASSEMBLY 2018 (control)    0.3%
--     1418525  DIXON FOR ASSEMBLY 2020 (control)        0.2%
--     1460531 / 1301155 / 1463128 (controls)            0.0%
--
-- ▶ **A $1.3M state-senate donor base and a small-city council donor base are different fundraising
-- universes** — party committees and unions against neighbours and local small donors. The test
-- needs COMPARABLE universes to discriminate; Dixon's Assembly and county-supervisor committees were
-- the same region and era, these are not. **A null result from a test that cannot discriminate is
-- not a negative finding**, and it must not be read as one in either direction.
--
-- 🟢 **WHAT DOES SETTLE IT: a multi-point biographical match across two independent sources.**
--
--   weho.org, the city's own councilmember page (primary):
--     "Councilmember John M. Erickson was elected to the West Hollywood City Council on
--      November 3, 2020"; "Ph.D. in American Religious History from **Claremont Graduate
--      University** and a Dual-Master's Degree from Claremont Graduate University"; "**University
--      of Wisconsin Oshkosh**"; "Vice President of Public Affairs … at **Planned Parenthood Los
--      Angeles**", now "Chief of Staff of Alliance for a Better Community".
--
--   ballotpedia.org/John_Erickson_(California), the SD-24 2026 candidate:
--     "Candidate, California State Senate District 24"; Ph.D. **Claremont Graduate University,
--      2011**; a second degree from the same institution; profession "**Nonprofit professional**";
--      high school **Ripon** (Ripon, Wisconsin, ~25 miles from UW Oshkosh).
--
--   A doctorate AND a second degree from the same institution, a nonprofit career, and a Wisconsin
--   upbringing — three specific attributes, matching across a city's official page and an
--   independent encyclopedia. Two John Ericksons in one county sharing all three is not credible.
--
--   Corroborating, from CAL-ACCESS's own CANDIDATE page (filer 1479090, the tool `CC_0216`
--   established): `ERICKSON, JOHN`, Democratic, **STATE SENATE DISTRICT 24, 2026 PRIMARY, WON**,
--   and the ONLY committee it lists as his is **1479089**. And the certified candidate list for the
--   2026 primary carries `ERICKSON, JOHN` under STATE SENATE 24.
--
-- ⚠ Neither CAL-ACCESS committee page carries an officeholder line or an address, and Ballotpedia's
-- page does **not** mention the council seat — so neither source alone closes it. The match is what
-- closes it.
--
--
-- ══ WHAT MOVES, AND THE ONE THAT IS NOT HIS ══════════════════════════════════════════════════
--
--   1479089  ERICKSON FOR STATE SENATE 2026; JOHN     980   $1,334,432.72   -> confirmed, his
--   1423886  ERICKSON FOR WH CITY COUNCIL 2020; JOHN    0   $        0.00   -> confirmed, his
--
-- 1423886 names the very seat the live row holds, which is the `CC_0212` test: the source naming the
-- seat beats the source naming the person.
--
-- 🔴 **THE THIRD IS NOT CANDIDATE-CONTROLLED, AND `CC_0213` TYPED IT `candidate_committee`:**
--
--   1489255  ERICKSON FOR STATE SENATE 2026, SPONSORED BY UNITE HERE LOCAL 11;
--            WORKING FAMILIES FOR JOHN                  1   $   25,000.00   -> ie_committee
--
-- It is **absent from his CAL-ACCESS candidate page**, which lists 1479089 alone — the same test
-- that told `CC_0216` which of Melissa Hurtado's two look-alike committees was hers. A committee
-- "sponsored by" a union and formed "for" a candidate is primarily-formed independent spending, and
-- publishing it as his own fundraising is the defect `campaignFinanceService.ts:28` records as fixed
-- on 2026-09-24. It moves to his row typed `ie_committee` and **`not_applicable`**, exactly as
-- `CC_0216` handled 1447993: `getOutsideSpendingForPolitician` scopes its totals to
-- `source_system = 'la_socrata'` and labels from `notes::jsonb->>'cmt_nm'`, so a `confirmed`
-- cal_access IE row would render an **unnamed card showing $0**. One UPDATE turns it on once that
-- function is widened.
--
-- End state on the live row: **1,738 contributions, $1,564,358.62** published — his two WEHO NetFile
-- committees plus the Senate committee — and one non-publishing IE row.

BEGIN;

DO $$
DECLARE
  r           record;
  v_cnt       bigint;
  v_n         bigint;
  v_sum       numeric;
  v_contrib0  bigint;
  v_live      uuid;
  v_scraped   uuid;
  n_moved     int := 0;
BEGIN
  -- ── idempotence
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id::text LIKE '29ccd743%' AND s.source_system = 'cal_access';
  IF v_cnt = 3 THEN
    RAISE NOTICE 'CC_0218: already applied (live row holds 3 cal_access sources) — skipping';
    RETURN;
  END IF;

  -- ── resolve both rows, by prefix AND name AND active state
  SELECT p.id INTO v_live FROM essentials.politicians p
   WHERE p.id::text LIKE '29ccd743%' AND p.full_name = 'John Erickson' AND p.is_active;
  IF v_live IS NULL THEN RAISE EXCEPTION 'CC_0218: no active "John Erickson" at 29ccd743 — refusing'; END IF;

  SELECT p.id INTO v_scraped FROM essentials.politicians p
   WHERE p.id::text LIKE 'af66146f%' AND p.full_name = 'John M. Erickson' AND NOT p.is_active;
  IF v_scraped IS NULL THEN RAISE EXCEPTION 'CC_0218: no inactive "John M. Erickson" at af66146f — refusing'; END IF;

  -- the live row must hold the West Hollywood council seat the evidence rests on
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
     WHERE t.politician_id = v_live AND g.name = 'City of West Hollywood'
  ) THEN
    RAISE EXCEPTION 'CC_0218: live row holds no City of West Hollywood term — identity chain broken';
  END IF;

  -- CC_0217 must have run: the scraped row carries 13 not_applicable and exactly 3 confirmed
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = v_scraped AND s.research_status = 'not_applicable';
  IF v_cnt <> 13 THEN
    RAISE EXCEPTION 'CC_0218: scraped row holds % not_applicable sources, expected 13 (run CC_0217 first)', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = v_scraped AND s.research_status = 'confirmed';
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'CC_0218: scraped row holds % confirmed sources, expected 3', v_cnt; END IF;

  -- the live row's own NetFile money, which must survive untouched
  SELECT count(c.id), coalesce(sum(c.amount), 0) INTO v_n, v_sum
    FROM transparent_motivations.politician_sources s
    LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.essentials_politician_id = v_live AND s.source_system = 'la_county_netfile';
  IF v_n <> 758 THEN RAISE EXCEPTION 'CC_0218: live row NetFile holds % contributions, expected 758', v_n; END IF;

  CREATE TEMP TABLE _srcs ON COMMIT DROP AS
    SELECT s.id FROM transparent_motivations.politician_sources s
     WHERE s.essentials_politician_id IN (v_live, v_scraped);
  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);

  -- ── move the three, each resolved by (external_id + the scraped row it hangs on)
  FOR r IN
    SELECT x.ext, x.stype, x.status, x.why
      FROM (VALUES
        ('1479089','candidate_committee','confirmed',
         'his own: CAL-ACCESS candidate page for ERICKSON, JOHN (filer 1479090, SD-24 2026) lists this committee and no other'),
        ('1423886','candidate_committee','confirmed',
         'his own: names the West Hollywood council seat the live row holds, and weho.org records his election to it on 2020-11-03'),
        ('1489255','ie_committee','not_applicable',
         'union-sponsored independent spending, absent from his CAL-ACCESS candidate page. Held at not_applicable only because getOutsideSpendingForPolitician scopes ie_all_sources to source_system=la_socrata and reads notes->cmt_nm; set confirmed once that is widened')
      ) AS x(ext, stype, status, why)
  LOOP
    SELECT count(*) INTO v_cnt
      FROM transparent_motivations.politician_sources s
     WHERE s.source_system = 'cal_access' AND s.external_id = r.ext
       AND s.essentials_politician_id = v_scraped;
    IF v_cnt <> 1 THEN
      RAISE EXCEPTION 'CC_0218: external_id % resolves to % sources on the scraped row, expected 1', r.ext, v_cnt;
    END IF;

    UPDATE transparent_motivations.politician_sources s
       SET essentials_politician_id = v_live,
           research_status          = r.status,
           source_type              = r.stype,
           notes                    = (s.notes::jsonb
                                        || jsonb_build_object('adjudicated_by','CC_0218',
                                                              'adjudication', r.why))::text,
           updated_at               = now()
     WHERE s.source_system = 'cal_access' AND s.external_id = r.ext
       AND s.essentials_politician_id = v_scraped;
    n_moved := n_moved + 1;
  END LOOP;

  IF n_moved <> 3 THEN RAISE EXCEPTION 'CC_0218: moved % sources, expected 3', n_moved; END IF;

  -- ══ POST-VERIFY ═════════════════════════════════════════════════════════════════════════════

  -- 1. The scraped row publishes NOTHING and keeps its 13 adjudicated orphans. It is not retired.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s WHERE s.essentials_politician_id = v_scraped;
  IF v_cnt <> 13 THEN RAISE EXCEPTION 'CC_0218: scraped row holds % sources, expected 13', v_cnt; END IF;

  SELECT count(c.id) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.essentials_politician_id = v_scraped
     AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0218: scraped row still publishes % contributions', v_cnt; END IF;

  IF EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v_scraped AND p.is_active) THEN
    RAISE EXCEPTION 'CC_0218: the scraped row became ACTIVE — refusing';
  END IF;

  -- 2. The live row publishes his NetFile council money AND his Senate committee: 1,738 / $1,564,358.62.
  SELECT count(DISTINCT s.id), count(c.id), coalesce(sum(c.amount), 0)
    INTO v_cnt, v_n, v_sum
    FROM transparent_motivations.politician_sources s
    LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.essentials_politician_id = v_live
     AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee';
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'CC_0218: live row holds % confirmed committees, expected 4', v_cnt; END IF;
  IF v_n <> 1738 THEN RAISE EXCEPTION 'CC_0218: live row publishes % contributions, expected 1738', v_n; END IF;
  IF round(v_sum, 2) <> 1564358.62 THEN
    RAISE EXCEPTION 'CC_0218: live row publishes %, expected 1564358.62', round(v_sum, 2);
  END IF;

  -- 3. 🔴 The union-sponsored committee must NOT be publishable as his own fundraising.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = v_live AND s.external_id = '1489255'
     AND s.source_type = 'ie_committee' AND s.research_status = 'not_applicable';
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'CC_0218: 1489255 is not recorded as a non-publishing ie_committee on the live row';
  END IF;

  -- 4. His NetFile council money survived exactly as it was — this migration must not disturb it.
  SELECT count(c.id), coalesce(sum(c.amount), 0) INTO v_n, v_sum
    FROM transparent_motivations.politician_sources s
    LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.essentials_politician_id = v_live AND s.source_system = 'la_county_netfile';
  IF v_n <> 758 OR round(v_sum, 2) <> 229925.90 THEN
    RAISE EXCEPTION 'CC_0218: NetFile money is now % / % , expected 758 / 229925.90', v_n, round(v_sum, 2);
  END IF;

  -- 5. No contribution row was touched or stranded.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_cnt <> v_contrib0 THEN
    RAISE EXCEPTION 'CC_0218: the two rows carried % contributions and now carry %', v_contrib0, v_cnt;
  END IF;

  RAISE NOTICE 'CC_0218: 3 sources moved to the live row; scraped row keeps 13 orphans and publishes nothing';
END $$;

COMMIT;
