-- 1904_tx_redistricting_rung1_ruling_season2.sql
-- The three Texas redistricting rows migration 1903 held out for the operator, now resolved.
-- One citation repair at an unchanged chair, and TWO CHAIR MOVES, 2 -> 1.
--
-- 🔴 WHY THIS IS A SEPARATE MIGRATION. Migration 1903 wrote 243 keys as CITATION REPAIRS and
-- BLANKS, and a repair may not move a chair. These three could not be settled by evidence at
-- all -- they turn on what rung 1's own words mean -- so they were held out and put to the
-- operator with the bill texts. This file carries the answer, and it moves chairs, which is why
-- it is not folded into 1903.
--
-- ══ ⚖ THE QUESTION, AND THE RULING ════════════════════════════════════════════════════════════
-- Rung 1 of the redistricting ladder reads:
--     "independent citizens' commissions with no elected officials involved at any level"
-- and rung 2:
--     "independent redistricting commissions with equal representation from both major parties"
--
-- 🔑 ALL TWELVE redistricting-commission bills filed by members of this cohort give elected
-- officials SOME role. The auditor-draw bills (Goodwin's HB 693 and HB 196, Morales Shaw's
-- HB 282) let the four party caucus leaders STRIKE eight applicants before the draw. The
-- agency-draw bills (Miles's and West's SJR 3 and SJR 2) give a four-legislator select committee
-- the power to approve or reject the applicant POOL. The rest seat appointees of the Speaker,
-- the Lieutenant Governor, senior members or the party caucuses outright.
--
-- So "involved at any level" admits two readings, and they give opposite answers:
--   (a) no elected official SERVES on the commission  -> the auditor and agency draws are rung 1
--   (b) no elected official TOUCHES the process       -> nothing filed in Texas is rung 1
--
-- ⚖ OPERATOR RULING, 2026-10-08: **(a) -- no elected official SERVES.** A caucus leader's power
-- to strike applicants, or a select committee's veto over the pool, is involvement in the
-- PROCESS and not membership of the commission. Reading (b) would mean no commission that
-- exists in the United States is rung 1: California's and Arizona's citizens' commissions both
-- give legislative leaders strikes.
--
-- ══ WHAT THE RULING DOES TO THE THREE ═════════════════════════════════════════════════════════
--   Vikki Goodwin       chair 1, UNCHANGED -- now confirmed by her own bill rather than resting
--                       on the original placement. A citation repair.
--   Penny Morales Shaw  chair 2 -> 1. 🔴 Her previous reasoning said "No authored independent
--                       redistricting bill found" -- she had COAUTHORED one, HB 282 (87R), and
--                       it is an all-citizen commission.
--   Borris Miles        chair 2 -> 1. 🔴 His previous reasoning rested on a COMMITTEE SEAT
--                       ("sits on the Congressional Redistricting Special Committee"). A seat is
--                       not a position -- members are assigned by leadership -- and meanwhile he
--                       is the AUTHOR of an all-citizen commission amendment in both 2025
--                       special sessions.
--
-- ══ ⚠ ROYCE WEST IS DELIBERATELY NOT MOVED, AND THE TENSION IS RECORDED ════════════════════════
-- West coauthored the same SJR 3 and SJR 2 as Miles, so under this ruling his 2025 filings are
-- rung 1. He is left at chair 2, which migration 1903 repaired, because his OWN earlier bills
-- -- SJR 56 (86R) and SJR 43 (87R) -- seat a seven-member commission appointed by the Speaker,
-- the Lieutenant Governor and the party caucuses, which is rung 2 on either reading. He is the
-- only member of this cohort who has filed BOTH shapes, and his most recent filing is the rung-1
-- one. Whether the latest filing should govern is a real question and is left open rather than
-- answered silently here.
--
-- ══ THE REST OF THE EVIDENCE, UNCHANGED FROM MIGRATION 1903 ═══════════════════════════════════
-- All three voted against HB 4 in the second called session of the 89th -- the 2025 mid-decade
-- congressional map -- and the two House members were absent and undisclaimed on all nine quorum
-- rolls taken while they served. That evidence establishes the SIDE of the ladder and always
-- did; what the commission bills add, and what the ruling unlocks, is the RUNG.
--
-- Season 1 is CLOSED and IMMUTABLE: these are forward writes into Season 2.
-- No migration runner exists; this file records SQL applied by hand.

DO $pre$
DECLARE n integer;
BEGIN
  -- 1. the three sit where migration 1903 left them: Season 1 chairs intact, no Season 2 row
  SELECT count(*) INTO n FROM (VALUES
    ('f39b0865-c923-428a-b940-09138c09e4e8'::uuid, 1),
    ('81d931a9-5906-4ff4-9ac8-15b49c4ae38a'::uuid, 2),
    ('67a35228-1353-4044-90b2-cd8fcf48de7b'::uuid, 2)
  ) AS k(pid, chair)
  JOIN inform.politician_answers s1
    ON s1.politician_id = k.pid
   AND s1.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
   AND s1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
   AND s1.value = k.chair;
  IF n <> 3 THEN
    RAISE EXCEPTION 'migration 1904: expected 3 Season 1 chairs at 1/2/2, found %', n;
  END IF;

  -- 2. migration 1903 held these out, so none may already have a Season 2 row
  SELECT count(*) INTO n FROM inform.politician_answers a
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND a.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
     AND a.politician_id IN ('f39b0865-c923-428a-b940-09138c09e4e8'::uuid,
                             '81d931a9-5906-4ff4-9ac8-15b49c4ae38a'::uuid,
                             '67a35228-1353-4044-90b2-cd8fcf48de7b'::uuid);
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1904: % of the 3 already have a Season 2 answer -- 1903 was supposed to hold them out', n;
  END IF;

  -- 3. the redistricting rung text is byte-identical across the two seasons, so the carry gate
  --    is satisfied by construction. Fail if that stops being true.
  SELECT count(*) INTO n
    FROM inform.compass_stance_revisions a
    JOIN inform.season_questions qa ON qa.topic_revision_id = a.topic_revision_id
     AND qa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
    JOIN inform.season_questions qb ON qb.topic_id = qa.topic_id
     AND qb.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
    JOIN inform.compass_stance_revisions b ON b.topic_revision_id = qb.topic_revision_id
     AND b.value = a.value
   WHERE qa.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
     AND a.value IN (1, 2) AND a.text IS DISTINCT FROM b.text;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1904: redistricting rung 1 or 2 text changed between seasons (%) -- re-read before carrying', n;
  END IF;
END
$pre$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
VALUES
  -- Vikki Goodwin / redistricting  (chair 1 -> 1, RUNG_CONFIRMED_BY_OWN_BILL)
    ('f39b0865-c923-428a-b940-09138c09e4e8'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Citation repaired 2026-10-08 (migration 1904); THE CHAIR IS UNCHANGED, and it is now carried by this member''s own bill rather than by the original placement. The row previously cited only a Wikipedia biography, which is not evidence of a position. 🔑 THE RECORD: Goodwin is the author of HB 3094 and HJR 127 (87R), HB 693 and HJR 48 (88R), and HB 196 and HJR 26 (89th, first called session), all establishing the Texas Redistricting Commission. The bill text, not the caption, is what settles the rung: the STATE AUDITOR randomly draws three citizens to screen applicants and then randomly draws the first eight commissioners from a majority, a minority and an independent subpool, and a commissioner is barred from holding state, federal or county office for ten years afterwards. No elected official sits on the commission. ⚖ RUNG 1 REQUIRES "no elected officials involved at any level", and the operator ruled on 2026-10-08 that this means no elected official SERVES on the commission -- the four caucus leaders'' power to strike eight applicants before the draw is involvement in the process, not membership. On the ladder as ruled, this is rung 1. 🔑 AND THE SIDE WAS NEVER IN DOUBT: she voted against HB 4 in the second called session of the 89th, the 2025 mid-decade congressional map, 88-52 on Record 30, and was absent and undisclaimed on all nine quorum rolls taken while she served -- both 2021 rolls and all seven of 2025.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB693', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=891&Bill=HB196', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=891&Bill=HJR26', 'https://capitol.texas.gov/tlodocs/88R/billtext/html/HB00693I.htm', 'http://journals.house.texas.gov/hjrnl/892/pdf/89C2DAY05FINAL.PDF', 'https://en.wikipedia.org/wiki/Vikki_Goodwin']::text[]),
  -- Penny Morales Shaw / redistricting  (chair 2 -> 1, CHAIR_MOVED_BY_OPERATOR_RULING)
    ('81d931a9-5906-4ff4-9ac8-15b49c4ae38a'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Chair moved from 2 to 1 on 2026-10-08 (migration 1904), and the citation repaired with it. The row previously cited a Wikipedia biography and a Texas Legislature member page, neither of which is evidence of a position, and its reasoning said in terms: "No authored independent redistricting bill found". 🔴 SHE HAD COAUTHORED ONE. THE RECORD: Morales Shaw is a coauthor of HB 282 (87R), "Relating to the Independent Citizen Redistricting Commission". Its text, not its caption, settles the rung: the STATE AUDITOR randomly draws three citizens from the pool of applicants to form a review panel, then randomly draws the first eight of fourteen commissioners from a majority, a minority and an independent subpool; a commissioner may not hold a federal, state or county office elected from Texas for ten years afterwards. No elected official sits on the commission. ⚖ RUNG 1 REQUIRES "no elected officials involved at any level", and the operator ruled on 2026-10-08 that this means no elected official SERVES on the commission -- the four caucus leaders'' power to strike eight applicants before the draw is involvement in the process, not membership. That is rung 1 and not rung 2, whose defining feature is a commission of party-balanced APPOINTEES. 🔑 THE SIDE WAS ALREADY ESTABLISHED: she voted against HB 4 in the second called session of the 89th, the 2025 mid-decade congressional map, 88-52 on Record 30, and was absent and undisclaimed on all nine quorum rolls taken while she served.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=HB282', 'https://capitol.texas.gov/tlodocs/87R/billtext/html/HB00282I.htm', 'http://journals.house.texas.gov/hjrnl/892/pdf/89C2DAY05FINAL.PDF', 'https://en.wikipedia.org/wiki/Penny_Morales_Shaw', 'https://capitol.texas.gov/Members/MemberInfo.aspx?Leg=89&Chamber=H&Code=A4035']::text[]),
  -- Borris Miles / redistricting  (chair 2 -> 1, CHAIR_MOVED_BY_OPERATOR_RULING)
    ('67a35228-1353-4044-90b2-cd8fcf48de7b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Chair moved from 2 to 1 on 2026-10-08 (migration 1904), and the citation repaired with it. The row previously cited only a Texas Legislature member page, and reasoned from a COMMITTEE SEAT -- that he "sits on the Congressional Redistricting Special Committee". 🔴 A SEAT IS NOT A POSITION: members are assigned to committees by leadership, and the assignment says nothing about what they would vote for. Meanwhile his own filed record contains the thing the row said it could not find. THE RECORD: Miles is the author of SJR 3 (89th, first called session) and SJR 2 (89th, second called session), "Proposing a constitutional amendment establishing an independent redistricting commission". Its text settles the rung: a NONPARTISAN AGENCY appoints fifteen commissioners CHOSEN AT RANDOM, two at a time, from the majority, minority and independent categories of a vetted selection pool, with alternates drawn the same way; the commission maintains a public website "not affiliated with or maintained by the office of any elected official". No elected official sits on it. The legislature''s only role is a four-member select committee that approves or rejects the selection POOL. ⚖ RUNG 1 REQUIRES "no elected officials involved at any level", and the operator ruled on 2026-10-08 that this means no elected official SERVES on the commission -- a veto over the pool is involvement in the process, not membership. That is rung 1, not the party-balanced APPOINTEES of rung 2. 🔑 THE SIDE WAS ALREADY ESTABLISHED: he voted against HB 4 in the Senate in the second called session of the 89th, 18-11, against the 2025 mid-decade congressional map.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=891&Bill=SJR3', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=892&Bill=SJR2', 'https://capitol.texas.gov/tlodocs/892/billtext/html/SJ00002I.htm', 'http://journals.senate.texas.gov/sjrnl/892/pdf/89S2SJ08-22-F.PDF', 'https://capitol.texas.gov/Members/MemberInfo.aspx?Leg=89&Chamber=S&Code=A1115']::text[]);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value)
VALUES
  -- Vikki Goodwin -> 1 (unchanged)
    ('f39b0865-c923-428a-b940-09138c09e4e8'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 1),
  -- Penny Morales Shaw -> 1 (moved from 2)
    ('81d931a9-5906-4ff4-9ac8-15b49c4ae38a'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 1),
  -- Borris Miles -> 1 (moved from 2)
    ('67a35228-1353-4044-90b2-cd8fcf48de7b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 1);

DO $post$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context c
    JOIN inform.politician_answers a
      ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
     AND a.season_id = c.season_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE '%(migration 1904)%'
     AND a.value = 1;
  IF n <> 3 THEN
    RAISE EXCEPTION 'migration 1904: expected 3 Season 2 rows at value 1 with context, found %', n;
  END IF;

  -- Season 1 must be untouched
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND reasoning LIKE '%migration 1904%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1904: % Season 1 rows were altered', n;
  END IF;
END
$post$;
