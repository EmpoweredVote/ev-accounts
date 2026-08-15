-- 1759_wa_task10_rescan_baron_mosqueda.sql
-- Two rows the Task 10 sweep could not have found, from re-checking its 20 blanks.
--
-- 🔴 TWO SEPARATE BLIND SPOTS, AND NEITHER WAS A RESEARCH FAILURE.
--
-- 1. THE DIVIDED-VOTE THRESHOLD. `votefirst.py divided` defaults to `--min-oppose 0.20`, and the
--    cached corpus was built at that default. A 20% floor CANNOT SEE AN 8-1 OR 9-2 FULL-COUNCIL VOTE
--    (11% and 18% against) -- and on a nine-member council that band is exactly where the LONE DISSENT
--    and the narrowly-carried authored bill live. Re-running at 0.10 took King County 118 -> 260 and
--    Seattle 146 -> 284. Jorge Barón's ordinance sits at 11% and was invisible.
--
-- 2. CROSS-OFFICE SERVICE. Teresa Mosqueda is bucketed as a King County councilmember, so only King
--    County Legistar was searched for her. She served on the SEATTLE City Council 2018-2023, and the
--    Task 10 write-up says in as many words that her record starts in 2024. Her Seattle service was
--    never examined. The cross-office precedent already exists in this corpus -- Zahilay's jail row is
--    evidence from his council service, written after he became County Executive.
-- 🔑 Generalise: a member's corpus is defined by WHERE THEY SERVED, not by which government currently
-- lists them. Check every office a person has held before calling their record thin.
--
-- ── Jorge Barón / local-immigration = 2 ───────────────────────────────────────────────────────
-- Ordinance 19963 (2025-0216), passed 8-1 on 2025-08-19. Barón is its SOLE SPONSOR, MOVED it to
-- passage, and voted yes -- the same evidence form migration 1754 accepted for Perry on Ord 19613.
-- ⚠ The Seattle sponsorship discount does not apply: this is King County, and there is no
-- executive-transmittal line in its history.
-- The ordinance extends K.C.C. chapter 2.15 -- the chapter created by Ordinance 18665, the very
-- instrument that seated Balducci and Dembowski at this chair -- to county CONTRACTORS. Its judicial
-- criminal warrant condition is chair 2's mechanism. Chair 1 fails on BOTH of its clauses, and this is
-- refutation rather than absence: its detainer clause is refuted by the chapter being amended (18665
-- honours detainers accompanied by a judicial warrant), and its information-sharing clause is
-- contradicted twice in this ordinance's own text.
--
-- ── Teresa Mosqueda / taxes = 1 ───────────────────────────────────────────────────────────────
-- CB 119810 (Ord 126108) and CB 119811 (Ord 126109), Seattle, both 2020-07-06. Mosqueda is a
-- CO-SPONSOR OF BOTH and voted in favour of both -- the exact standard migration 1754 applied to
-- Strauss on this same instrument pair, which the operator approved. Seating her differently would
-- make the corpus inconsistent with itself on identical evidence.
-- ⚠ The counter-argument is carried forward verbatim from that decision rather than quietly dropped:
-- section 2.A is chair 2's language for 2021 only, and neither instrument characterises the increase as
-- significant or moderate, so the chair rests on the DESTINATION in section 2.B, which is permanent and
-- is entirely new investment.
--
-- ⬜ Deliberately NOT seated, and the reasons are worth keeping: Reagan Dunn is the lone No on a large
-- share of the newly visible 11% items, but opposing a proposal is DIRECTION, not a chair -- the same
-- disposition 1754 gave him on jail-capacity and local-immigration. Kettle, Rivera, Saka, Rinck and
-- Hollingsworth sponsor or dissent only on surveillance authorisations, solid-waste rates, levy
-- implementation plans and graffiti enforcement, none of which describes a ladder.
--
-- Full pass, including every rejected candidate:
-- data/stance-research/2026-08-15-wa-task10-blank-recheck.md
BEGIN;

CREATE TEMP TABLE rs_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*)
          FROM inform.politician_context pc
          LEFT JOIN inform.politician_answers pa
            ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
         WHERE pa.politician_id IS NULL
           AND coalesce(cardinality(pc.sources), 0) > 0
           AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
           AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)'
       ) AS orphans_before;

CREATE TEMP TABLE rs_new (pid uuid, tid uuid, chair numeric) ON COMMIT DROP;
INSERT INTO rs_new VALUES
  ('d167607d-f8fd-442e-9397-8fd677d2deb7','b9ccee94-ad96-4f10-b655-889d8e5abe92', 2),  -- Barón / local-immigration
  ('341e2bc1-37ef-4b18-9f64-8dae8f7e6079','f7e5678d-dadd-4556-a2fc-446e24642ceb', 1);  -- Mosqueda / taxes

DO $$
DECLARE n int;
BEGIN
  -- Neither pair may already exist. If one does, someone researched it since this pass and their work
  -- must not be overwritten from a stale worklist.
  SELECT count(*) INTO n FROM rs_new r
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers a
                  WHERE a.politician_id=r.pid AND a.topic_id=r.tid)
      OR EXISTS (SELECT 1 FROM inform.politician_context c
                  WHERE c.politician_id=r.pid AND c.topic_id=r.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % pair(s) already have a row', n; END IF;

  -- Each chair must be defined exactly once on its own ladder; a value with no stance row renders blank.
  SELECT count(*) INTO n FROM rs_new r
   WHERE NOT EXISTS (SELECT 1 FROM inform.compass_stances s
                      WHERE s.topic_id=r.tid AND s.value=r.chair);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % chair(s) undefined on their ladder', n; END IF;

  -- Both topics must still be live and role-unscoped, or the row cannot render for these offices.
  SELECT count(*) INTO n FROM rs_new r
    JOIN inform.compass_topics t ON t.id=r.tid
   WHERE NOT t.is_live OR t.judicial_role IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % topic(s) not live/unscoped', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('d167607d-f8fd-442e-9397-8fd677d2deb7','b9ccee94-ad96-4f10-b655-889d8e5abe92',
 $r$On August 19, 2025 the Metropolitan King County Council passed Ordinance 19963 by a divided vote of eight to one. Barón is the ordinance's sole sponsor, moved it to passage and voted yes. The ordinance extends the county's civil immigration enforcement chapter to organisations holding county contracts. In performing its obligations under its contract a contractor may not expend time, moneys or other resources on facilitating the civil enforcement of federal immigration law or participate in civil immigration enforcement operations except where a state or federal law, regulation, court order or rule requires it, and may not permit ICE, CBP or USCIS officers access to nonpublic areas of its facilities, property, equipment or nonpublic databases for the purpose of civil immigration enforcement against people receiving services under the contract, "absent a judicial criminal warrant specifying the information or persons sought". That judicial warrant condition is the mechanism this chair names, and it is the same standard the council applied to detainers in Ordinance 18665, the ordinance this one amends. The chair calling for refusing all cooperation and barring the sharing of immigration status information is refuted rather than merely unsupported, on both of its elements: the chapter being amended honours detainers when they are accompanied by a judicial warrant, and this ordinance states twice that a contractor is not prohibited from sending to or receiving from federal immigration authorities the citizenship or immigration status of a person, and may exchange that information with any federal, state or local agency and maintain it. The adjacent chair below, which follows federal law as required without devoting local resources to proactive enforcement, is exceeded rather than met, because requiring a judicial criminal warrant before granting access is an affirmative limit rather than compliance as required.$r$,
 ARRAY['https://kingcounty.legistar1.com/kingcounty/attachments/1dc10b23-e710-4979-b9f6-323677bb8ebe.pdf']),
('341e2bc1-37ef-4b18-9f64-8dae8f7e6079','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Mosqueda co-sponsored both halves of Seattle's JumpStart payroll expense tax while serving on the Seattle City Council, and voted for both. Council Bill 119810, which became Ordinance 126108, passed seven votes to two on July 6, 2020 and levies a payroll expense tax graduated on employer size and salary, reaching two and four-tenths percent on the highest compensation at businesses with payroll of one billion dollars or more. The companion spending plan, Council Bill 119811, which became Ordinance 126109, passed eight to one the same day with Mosqueda again in favour and again a co-sponsor. The mayor returned both unsigned, so this was council-authored legislation rather than executive legislation carried by a council sponsor, which is why the sponsorship counts here. The spending plan is what places her at funding more public services rather than existing ones: section 2.B, governing all years after the first, directs the proceeds to capital costs for the construction or acquisition of housing for low-income households, to operating and services costs for rental housing serving households at or below thirty percent of area median income, to rental assistance, to the Equitable Development Initiative, to support for local businesses and tourism, and to investments that advance Seattle's Green New Deal. Recorded against that reading: section 2.A, which applies to 2021 only, replenishes the city's Emergency Fund and Revenue Stabilization Fund and funds continuity of services the city supported before the COVID-19 crisis, which is language belonging to the adjacent chair; that provision is expressly transitional while section 2.B is the permanent structure. Neither instrument characterises the increase as significant or moderate in its own terms, so the chair rests on the destination of the revenue rather than on stated magnitude.$r$,
 ARRAY['https://legistar2.granicus.com/seattle/attachments/7404af72-ad86-44c5-87d3-adadb4d17aa0.pdf',
       'https://legistar2.granicus.com/seattle/attachments/960f43a8-369f-4d82-8736-530e50712742.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pid, tid, chair FROM rs_new;

-- Guard 1: exactly two answers and two context rows appear, and nothing else moves.
DO $$
DECLARE a int; c int; s record;
BEGIN
  SELECT * INTO s FROM rs_snap;
  SELECT count(*) INTO a FROM inform.politician_answers;
  SELECT count(*) INTO c FROM inform.politician_context;
  IF a <> s.ans_before + 2 THEN RAISE EXCEPTION 'guard 1: answers % -> %, expected +2', s.ans_before, a; END IF;
  IF c <> s.ctx_before + 2 THEN RAISE EXCEPTION 'guard 1: context % -> %, expected +2', s.ctx_before, c; END IF;
END $$;

-- Guard 2: each row sits at the chair that was read, carries the sentence it was verified on, and cites
-- the document that sentence came from. Checked on CONTENT, not on the fact that an INSERT ran.
DO $$
DECLARE r text; srcs text[]; v numeric;
BEGIN
  SELECT a.value, c.reasoning, c.sources INTO v, r, srcs
    FROM inform.politician_answers a JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.politician_id='d167607d-f8fd-442e-9397-8fd677d2deb7'
     AND a.topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF v <> 2 THEN RAISE EXCEPTION 'guard 2: Barón chair is %, expected 2', v; END IF;
  IF r !~ 'absent a judicial criminal warrant' THEN
    RAISE EXCEPTION 'guard 2: Barón reasoning lacks the verified quotation'; END IF;
  IF NOT (srcs @> ARRAY['https://kingcounty.legistar1.com/kingcounty/attachments/1dc10b23-e710-4979-b9f6-323677bb8ebe.pdf']) THEN
    RAISE EXCEPTION 'guard 2: Barón row does not cite Ordinance 19963'; END IF;

  SELECT a.value, c.reasoning, c.sources INTO v, r, srcs
    FROM inform.politician_answers a JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.politician_id='341e2bc1-37ef-4b18-9f64-8dae8f7e6079'
     AND a.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF v <> 1 THEN RAISE EXCEPTION 'guard 2: Mosqueda chair is %, expected 1', v; END IF;
  IF r !~ 'section 2.B' THEN
    RAISE EXCEPTION 'guard 2: Mosqueda reasoning does not rest on the permanent destination'; END IF;
  IF cardinality(srcs) <> 2 THEN
    RAISE EXCEPTION 'guard 2: Mosqueda row must cite BOTH halves of the instrument pair'; END IF;
END $$;

-- Guard 3: the two gate invariants. Writing an answer is the operation that publishes reasoning, so
-- ORPHAN_CONTEXT is asserted here rather than left for CI to discover.
DO $$
DECLARE orphans int; ans_wo_ctx int; s record;
BEGIN
  SELECT * INTO s FROM rs_snap;
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> s.orphans_before THEN
    RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT moved % -> %', s.orphans_before, orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'Task 10 re-check: Barón local-immigration=2, Mosqueda taxes=1';
END $$;

COMMIT;
