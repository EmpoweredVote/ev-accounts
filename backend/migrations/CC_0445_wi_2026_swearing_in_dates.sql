-- CC_0445 — Wisconsin 2026 swearing-in dates. 123 offices, one day, four authorities.
--
-- Piece 4 of the post-election transition programme, Wisconsin slice. Before this, the whole
-- legislative tier of the programme carried NO swearing-in date anywhere in the country; in
-- Wisconsin only the 8 US House seats had one. This is the first state legislature to get them.
--
-- Rules, sources and the verbatim statutory text: backend/data/wi-2026-swearing-in/RULES.md
--
-- ─────────────────────────────────────────────────────────────────────────────
-- EVERY WISCONSIN OFFICE ELECTED 2026-11-03 HANDS OVER ON **MONDAY 2027-01-04**.
-- That is the first Monday of January 2027 — computed, not assumed; 2027-01-01 is a Friday.
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Four authorities, because one rule does not cover them and assuming it would is the trap
-- the California slice already paid for:
--
--   99 Assembly + 17 Senate   Wis. Const. art. XIII § 1 — "The political year for this state
--                             shall commence on the first Monday of January in each year" —
--                             with Wis. Stat. § 13.02(1), which convenes the legislature "in
--                             the capitol on the first Monday of January in each odd-numbered
--                             year, at 2 p.m., TO TAKE THE OATH OF OFFICE".
--    5 statewide executives   Wis. Const. art. XIII § 1 (same political-year rule), the terms
--                             being fixed by art. V § 1 (governor and lieutenant governor,
--                             4 years) and art. VI § 1 (secretary of state, treasurer and
--                             attorney general, 4 years).
--    1 county sheriff         Wis. Stat. § 59.20(2)(b) — "The regular term of office of each
--                             sheriff and coroner shall commence on the first Monday in
--                             January next succeeding his or her election".
--    1 clerk of circuit court Wis. Stat. § 59.20(2)(bm) — same words for that office.
--
-- 🔴 § 59.20(2) IS NOT A BLANKET COUNTY RULE AND READING IT AS ONE WOULD HAVE BEEN WRONG.
--   Paragraph (a) names only the register of deeds, county clerk, treasurer and surveyor —
--   NOT the sheriff, NOT the clerk of circuit court. Each is granted its own paragraph, and
--   paragraph (am) puts the comptroller on the **3rd Tuesday in April** instead. The
--   subsection contains a counter-example to its own apparent pattern. Cite the paragraph.
--
-- 🔴 ONLY 17 OF THE 33 SENATE SEATS ARE HERE, AND THAT IS CORRECT.
--   Wis. Const. art. IV § 5: "the senators shall be chosen alternately from the odd and
--   even-numbered districts for the term of 4 years." The odd districts were up in 2026; the
--   16 even-numbered senators are mid-term and this election does not touch them. A pass that
--   expected 33 would read 16 absences as drift. The gate below asserts 17 and asserts every
--   one of them is odd-numbered.
--
-- CORROBORATION, specific to this cycle rather than to the general rule:
--   2025 Senate Joint Resolution 1 (enrolled), § 1(1): "the biennial session period of the
--   2025 Wisconsin Legislature began on Monday, January 6, 2025, and ... ends at noon on
--   Monday, January 4, 2027." The outgoing session ends at noon; § 13.02(1) convenes the
--   incoming one at 2 p.m. the same day.
--
-- ⚠ THE § 13.02(1) ADJUSTMENT IS LIVE, IT JUST DOES NOT BITE THIS CYCLE. The statute moves
--   the day to January 3 "if the first Monday of January falls on January 1 or 2". That
--   happened in 2023 — first Monday was Jan 2 — and Wisconsin swore in the governor,
--   lieutenant governor, attorney general, secretary of state, treasurer AND both houses on
--   Jan 3, 2023. So the executives follow the adjusted legislative day in practice, not the
--   unadjusted political-year date. In 2027 the first Monday is the 4th and nothing moves.
--
-- 🔴 THIS MIGRATION SEATS NOBODY. It records WHEN the handover happens, not that it has.
--   2027-01-04 is in the future. Every losing Wisconsin incumbent still holds their seat
--   today and must keep it until that date. The seating pass is a separate migration on or
--   after 2027-01-04, and that is where `p_allow_reelection` and the `is_vacant` trap bite.
--
-- OVERWRITES NOTHING: `essentials.office_swearing_in` held zero Wisconsin rows outside the
-- 8 US House seats, which this does not touch. Guarded, so a row another session writes in
-- between is kept and the post-verify then fails loudly instead of silently disagreeing.

BEGIN;

-- Pre-check: the groups must be exactly the size the authorities above describe, BEFORE
-- anything is written. A count that disagrees means the scope moved under this file.
DO $$
DECLARE
  v_asm int; v_sen int; v_exec int; v_cty int; v_existing int;
BEGIN
  SELECT
    count(*) FILTER (WHERE d.district_type = 'STATE_LOWER'),
    count(*) FILTER (WHERE d.district_type = 'STATE_UPPER'),
    count(*) FILTER (WHERE d.district_type = 'STATE_EXEC'),
    count(*) FILTER (WHERE d.district_type = 'COUNTY')
    INTO v_asm, v_sen, v_exec, v_cty
    FROM (SELECT DISTINCT o.id, o.district_id
            FROM essentials.offices o
            JOIN essentials.races r ON r.office_id = o.id
            JOIN essentials.elections e ON e.id = r.election_id
           WHERE e.election_date = DATE '2026-11-03') q
    JOIN essentials.offices o ON o.id = q.id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) IN ('wi', '55');

  IF (v_asm, v_sen, v_exec, v_cty) IS DISTINCT FROM (99, 17, 5, 2) THEN
    RAISE EXCEPTION 'CC_0445: scope moved — assembly %, senate %, exec %, county % (expected 99/17/5/2)',
      v_asm, v_sen, v_exec, v_cty;
  END IF;

  -- Art. IV § 5 says the senate alternates odd and even. Prove the 17 really are the odd ones
  -- rather than trusting the count: a wrong 17 would also be 17.
  SELECT count(*) INTO v_existing
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.races r ON r.office_id = o.id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
   WHERE lower(d.state) IN ('wi','55') AND d.district_type = 'STATE_UPPER'
     AND (substring(d.ocd_id from 'sldu:([0-9]+)$')::int % 2) = 0;
  IF v_existing <> 0 THEN
    RAISE EXCEPTION 'CC_0445: % even-numbered senate district(s) carry a 2026 race — art. IV § 5 says the odd districts were up', v_existing;
  END IF;
END $$;

-- 99 Assembly seats
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT DISTINCT o.id, DATE '2026-11-03', DATE '2027-01-04', 'statute', 'wi-legislature-first-monday',
  'Wis. Const. art. XIII § 1 — "The political year for this state shall commence on the first Monday of January in each year" — with Wis. Stat. § 13.02(1), which convenes the legislature "in the capitol on the first Monday of January in each odd-numbered year, at 2 p.m., to take the oath of office". Assembly terms are biennial under art. IV § 4.',
  'https://docs.legis.wisconsin.gov/document/wisconsinconstitution/XIII,1 and https://docs.legis.wisconsin.gov/statutes/statutes/13/i/02 (both read 2026-11-16). Cycle-specific corroboration: 2025 Senate Joint Resolution 1 (enrolled), § 1(1), "the biennial session period ... ends at noon on Monday, January 4, 2027" — https://docs.legis.wisconsin.gov/2025/related/enrolled/sjr1',
  'First Monday of January 2027, computed: 2027-01-01 is a Friday, so the first Monday is the 4th. The s.13.02(1) adjustment to January 3 applies only when the first Monday is January 1 or 2, which it is not this cycle.'
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.races r ON r.office_id = o.id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
 WHERE lower(d.state) IN ('wi','55') AND d.district_type = 'STATE_LOWER'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_swearing_in s
                    WHERE s.office_id = o.id AND s.election_date = DATE '2026-11-03');

-- 17 Senate seats (odd-numbered districts; art. IV § 5)
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT DISTINCT o.id, DATE '2026-11-03', DATE '2027-01-04', 'statute', 'wi-legislature-first-monday',
  'Wis. Const. art. XIII § 1 — "The political year for this state shall commence on the first Monday of January in each year" — with Wis. Stat. § 13.02(1), which convenes the legislature "in the capitol on the first Monday of January in each odd-numbered year, at 2 p.m., to take the oath of office". Senate terms are 4 years, the odd and even districts alternating, under art. IV § 5.',
  'https://docs.legis.wisconsin.gov/document/wisconsinconstitution/XIII,1 and https://docs.legis.wisconsin.gov/statutes/statutes/13/i/02 (both read 2026-11-16). Cycle-specific corroboration: 2025 Senate Joint Resolution 1 (enrolled), § 1(1), "the biennial session period ... ends at noon on Monday, January 4, 2027" — https://docs.legis.wisconsin.gov/2025/related/enrolled/sjr1',
  'Only the 17 odd-numbered districts were on the 2026 ballot. The 16 even-numbered senators are mid-term and get no row for this election.'
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.races r ON r.office_id = o.id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
 WHERE lower(d.state) IN ('wi','55') AND d.district_type = 'STATE_UPPER'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_swearing_in s
                    WHERE s.office_id = o.id AND s.election_date = DATE '2026-11-03');

-- 5 statewide executives
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT DISTINCT o.id, DATE '2026-11-03', DATE '2027-01-04', 'statute', 'wi-state-exec-first-monday',
  'Wis. Const. art. XIII § 1 — "The political year for this state shall commence on the first Monday of January in each year". Terms: art. V § 1 (governor holds office for 4 years, "a lieutenant governor shall be elected at the same time and for the same term") and art. VI § 1 (electors "shall in 1970 and every 4 years thereafter elect a secretary of state, treasurer and attorney general who shall hold their offices for 4 years").',
  'https://docs.legis.wisconsin.gov/document/wisconsinconstitution/XIII,1 , /V,1 and /VI,1 (all read 2026-11-16). Practice corroboration: in 2023 the first Monday fell on January 2, so Wis. Stat. § 13.02(1) moved the legislature''s oath day to January 3, and the governor, lieutenant governor, attorney general, secretary of state and treasurer were all sworn in that same January 3 — the executives follow the adjusted legislative day.',
  'Governor, Lieutenant Governor, Attorney General, Secretary of State and Treasurer. No adjustment applies in 2027: the first Monday is January 4.'
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.races r ON r.office_id = o.id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
 WHERE lower(d.state) IN ('wi','55') AND d.district_type = 'STATE_EXEC'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_swearing_in s
                    WHERE s.office_id = o.id AND s.election_date = DATE '2026-11-03');

-- 1 county sheriff — its own paragraph, NOT the general county rule
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT DISTINCT o.id, DATE '2026-11-03', DATE '2027-01-04', 'statute', 'wi-county-sheriff-59-20-2-b',
  'Wis. Stat. § 59.20(2)(b) — "The regular term of office of each sheriff and coroner shall commence on the first Monday in January next succeeding his or her election and shall continue 4 years and until his or her successor qualifies." The office is constitutional: Wis. Const. art. VI § 4(1)(b) elects sheriffs for a 4-year term.',
  'https://docs.legis.wisconsin.gov/document/statutes/59.20 and https://docs.legis.wisconsin.gov/document/wisconsinconstitution/VI,4 (both read 2026-11-16)',
  'Cited to paragraph (b), not to § 59.20(2) as a whole: paragraph (a) names only the register of deeds, county clerk, treasurer and surveyor, and paragraph (am) puts the comptroller on the 3rd Tuesday in April.'
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.races r ON r.office_id = o.id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
 WHERE lower(d.state) IN ('wi','55') AND d.district_type = 'COUNTY' AND o.title = 'Sheriff'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_swearing_in s
                    WHERE s.office_id = o.id AND s.election_date = DATE '2026-11-03');

-- 1 clerk of circuit court — again its own paragraph
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT DISTINCT o.id, DATE '2026-11-03', DATE '2027-01-04', 'statute', 'wi-county-clerk-circuit-59-20-2-bm',
  'Wis. Stat. § 59.20(2)(bm) — "The regular term of office of each clerk of circuit court shall commence on the first Monday of January next succeeding his or her election and shall continue 4 years and until his or her successor qualifies."',
  'https://docs.legis.wisconsin.gov/document/statutes/59.20 (read 2026-11-16)',
  'Cited to paragraph (bm). § 59.20(2)(a) does not name this office.'
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.races r ON r.office_id = o.id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
 WHERE lower(d.state) IN ('wi','55') AND d.district_type = 'COUNTY' AND o.title = 'Clerk of Circuit Court'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_swearing_in s
                    WHERE s.office_id = o.id AND s.election_date = DATE '2026-11-03');

DO $$
DECLARE
  v_total int; v_wrong_date int; v_odd int; v_leak int; v_bad text;
  v_asm int; v_sen int; v_exec int; v_sheriff int; v_clerk int;
BEGIN
  SELECT count(*) INTO v_total
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03' AND lower(d.state) IN ('wi','55')
     AND d.district_type <> 'NATIONAL_LOWER';
  IF v_total <> 123 THEN
    RAISE EXCEPTION 'CC_0445: % Wisconsin non-congressional rows for this election, expected 123', v_total;
  END IF;

  -- Every one of them on the computed day, and nothing else.
  SELECT count(*) INTO v_wrong_date
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03' AND lower(d.state) IN ('wi','55')
     AND d.district_type <> 'NATIONAL_LOWER' AND s.swearing_in_date <> DATE '2027-01-04';
  IF v_wrong_date <> 0 THEN
    RAISE EXCEPTION 'CC_0445: % row(s) are not on 2027-01-04', v_wrong_date;
  END IF;

  -- The day must really be the first Monday of January 2027. Asserted, not trusted: a
  -- transcription slip of one day would otherwise pass every count above.
  IF EXTRACT(ISODOW FROM DATE '2027-01-04') <> 1
     OR EXTRACT(DAY FROM DATE '2027-01-04') > 7
     OR EXTRACT(MONTH FROM DATE '2027-01-04') <> 1
     OR EXTRACT(YEAR FROM DATE '2027-01-04') <> 2027 THEN
    RAISE EXCEPTION 'CC_0445: 2027-01-04 is not the first Monday of January 2027';
  END IF;

  -- Per-group counts, so a right total made of wrong parts cannot pass.
  SELECT count(*) FILTER (WHERE d.district_type = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type = 'STATE_UPPER'),
         count(*) FILTER (WHERE d.district_type = 'STATE_EXEC'),
         count(*) FILTER (WHERE d.district_type = 'COUNTY' AND o.title = 'Sheriff'),
         count(*) FILTER (WHERE d.district_type = 'COUNTY' AND o.title = 'Clerk of Circuit Court')
    INTO v_asm, v_sen, v_exec, v_sheriff, v_clerk
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03' AND lower(d.state) IN ('wi','55')
     AND d.district_type <> 'NATIONAL_LOWER';
  IF (v_asm, v_sen, v_exec, v_sheriff, v_clerk) IS DISTINCT FROM (99, 17, 5, 1, 1) THEN
    RAISE EXCEPTION 'CC_0445: per-group counts are %/%/%/%/% (expected 99/17/5/1/1)',
      v_asm, v_sen, v_exec, v_sheriff, v_clerk;
  END IF;

  -- 🔴 EACH GROUP MUST CARRY *ITS OWN* RULE, WHICH IS A DIFFERENT CLAIM FROM "the rule_id is
  --   one of the four". An earlier version of this gate only checked membership of the
  --   allowed set, and TWO controls walked straight through it: giving the executives the
  --   legislature's rule_id passed, and widening the sheriff INSERT so it also claimed the
  --   clerk of circuit court passed. Both left a row citing a statute that does not govern
  --   it — the exact defect this file was written to avoid — while every count stayed right.
  --   Assert the PAIRING, not the vocabulary.
  SELECT string_agg(x.label || ' → ' || x.rule_id, ', ') INTO v_bad FROM (
    SELECT DISTINCT d.district_type ||
             CASE WHEN d.district_type = 'COUNTY' THEN '/' || o.title ELSE '' END AS label,
           coalesce(s.rule_id, '(null)') AS rule_id
      FROM essentials.office_swearing_in s
      JOIN essentials.offices o ON o.id = s.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE s.election_date = DATE '2026-11-03' AND lower(d.state) IN ('wi','55')
       AND d.district_type <> 'NATIONAL_LOWER'
  ) x
  WHERE (x.label, x.rule_id) NOT IN (
    ('STATE_LOWER',                     'wi-legislature-first-monday'),
    ('STATE_UPPER',                     'wi-legislature-first-monday'),
    ('STATE_EXEC',                      'wi-state-exec-first-monday'),
    ('COUNTY/Sheriff',                  'wi-county-sheriff-59-20-2-b'),
    ('COUNTY/Clerk of Circuit Court',   'wi-county-clerk-circuit-59-20-2-bm'));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0445: group cited to the wrong rule: %', v_bad;
  END IF;

  -- And every one of the five pairings must actually be present, so a group that vanished
  -- cannot pass the check above by having nothing to disagree with.
  SELECT count(DISTINCT d.district_type ||
                CASE WHEN d.district_type = 'COUNTY' THEN '/' || o.title ELSE '' END
                || '|' || coalesce(s.rule_id,'(null)'))
    INTO v_odd
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03' AND lower(d.state) IN ('wi','55')
     AND d.district_type <> 'NATIONAL_LOWER';
  IF v_odd <> 5 THEN
    RAISE EXCEPTION 'CC_0445: % distinct group/rule pairing(s), expected 5', v_odd;
  END IF;

  -- No row may have leaked onto an office outside Wisconsin or onto a Wisconsin office with
  -- no 2026-11-03 race. A predicate-driven INSERT is exactly where that happens.
  SELECT count(*) INTO v_leak
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.rule_id IN ('wi-legislature-first-monday','wi-state-exec-first-monday',
                       'wi-county-sheriff-59-20-2-b','wi-county-clerk-circuit-59-20-2-bm')
     AND (lower(d.state) NOT IN ('wi','55')
          OR NOT EXISTS (SELECT 1 FROM essentials.races r
                           JOIN essentials.elections e ON e.id = r.election_id
                          WHERE r.office_id = o.id AND e.election_date = DATE '2026-11-03'));
  IF v_leak <> 0 THEN
    RAISE EXCEPTION 'CC_0445: % row(s) landed outside the intended scope', v_leak;
  END IF;

  -- Nobody is seated by this file. The handover is in the future and the incumbents still hold.
  SELECT count(*) INTO v_odd
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) IN ('wi','55') AND t.term_start = DATE '2027-01-04';
  IF v_odd <> 0 THEN
    RAISE EXCEPTION 'CC_0445: % Wisconsin term(s) already start on 2027-01-04 — this file records the date, it does not seat anyone', v_odd;
  END IF;

  RAISE NOTICE 'CC_0445 OK: 123 Wisconsin offices hand over on 2027-01-04 (99 assembly / 17 senate / 5 exec / 1 sheriff / 1 clerk of circuit court); nobody seated.';
END $$;

COMMIT;
