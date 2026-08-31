-- CA_0044_abortion_chair3_ambiguous_reaudit.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
--
-- NOTE ON NUMBER: CA_0040 (City Sanitation), CA_0041 (campaign finance v3) and CA_0042 (campaign
-- transparency) were already claimed/merged; the numbering check reported CA_0043 free, but a
-- pushed-later housing / rent-regulation migration is claiming CA_0043 on an unpushed branch (the exact
-- two-authors-same-number race CLAUDE.md warns about, invisible to fetch), so this took CA_0044.
-- No prod data embeds this migration's own number; the data change is applied once, ad hoc.
--
-- WHAT / WHY
-- Follow-up to CA_0039. The `abortion` topic (id af2fdfd6-02c4-49df-b09c-cf8536f4773f) was reworded and
-- published as a CLARIFYING revision (revision 5, id 085feb9c, version 1) that fixed the old 3-vs-4
-- collision by removing the "rape, incest, or maternal health" clause from chair 3:
--   NEW chair 3: "allow abortion during the first trimester, and after that only to protect the
--                 mother's health."   (an ELECTIVE first-trimester window is the defining feature)
--   NEW chair 4: "ban abortion except in cases of rape, incest, or a serious risk to the mother's
--                 life."              (a ban with exceptions; no elective window)
-- Season-1 answers are still PINNED to revision 1 (dab46e5c) but ADR 0006 (Option Y) renders the latest
-- published revision of the pinned VERSION, so voters already see the new chair-3 wording. Changing an
-- answer's `value` re-renders it against that new wording.
--
-- CA_0039 corrected 4 clear cases and LEFT 45 Season-1 rows at value 3 flagged AMBIGUOUS. This
-- migration re-audits those 45 against a PRIMARY-SOURCE bar and dispositions each one.
--
-- CITATION BAR (Andrews, per CA_0033/CA_0039): a chair must rest on a PRIMARY instrument produced by
-- the officeholder themselves — an authored/co-authored bill, a recorded floor vote, an official
-- statement, or their own campaign site / questionnaire answer. Wikipedia, OnTheIssues, interest-group
-- scorecards, party affiliation, and "would likely support" are NOT evidence.
--
-- KEY FINDING (same as CA_0039, confirmed row by row): most of these 45 rested ONLY on co-authorship of
-- HB 44 / SB 31 (89R), the bipartisan "Life of the Mother Act" (SB 31 passed the House 134-4, 60+
-- co-authors from both parties). That medical-emergency clarification establishes only DIRECTION — it
-- does NOT distinguish chair 3 from chair 4, and it is NOT evidence of an elective first-trimester
-- window. A lone vote AGAINST a ban is likewise direction only (consistent with chairs 1, 2 or 3). So a
-- row is only MOVED or RESEATED when a DIFFERENT primary instrument places a specific chair; otherwise
-- it is a documented blank. Full per-row research + verification: scratchpad verdicts.md.
--
-- DISPOSITIONS (45 rows)
--   MOVE 3 -> 4 (7) — a primary instrument backs the ABORTION BAN itself, + HB 44 supplies the
--   life-of-mother exception (ban with exceptions, no elective window):
--     Charlie Geren   87R recorded Yea on SB 8 (Heartbeat Act, Record 784) and HB 1280 (trigger ban,
--                     Record 793)  [House Journal verified]
--     Drew Darby      same two Yea votes; co-authored HB 1806 (89R, bars govt support for procurement)
--     Keith Bell      same two Yea votes; co-authored HB 1806
--     Lacey Hull      same two Yea votes; co-authored HB 1806
--     Mano DeAyala    not seated in 2021; co-authored HB 1806 (anti-procurement) + HB 44 (exception)
--     Stan Gerdes     own campaign site endorses the Heartbeat Bill + Trigger Ban and pledges to defend
--     Janie Lopez     own iVoterGuide answer "Abortion should not be allowed" + "shut down abortion
--                     clinics"; anti-procurement funding bill; HB 44 exception
--   RESEAT 3 -> 1 (4) — a primary instrument shows BROAD access (repeal a ban / codify a right / fund):
--     C. Anthony Muse recorded MD Senate Yea on SB 798 (2023 Right to Reproductive Freedom, no limit)
--     Vikki Goodwin   authored HB 2251 (89R, repeal of abortion-prohibition laws) + HJR 33; NO on bans
--     Gene Wu         own statement backing "safe and legal abortion" / bodily autonomy; NO on bans
--     Venton Jones    own campaign platform: "restore abortion access and funding for reproductive
--                     healthcare"
--   RESEAT 3 -> 2 (2) — a primary instrument sets an elective right up to a VIABILITY-type line:
--     Ana Hernandez   own Dobbs statement seeking to restore the pre-Dobbs constitutional right; NO on
--                     bans
--     John Bucy III   authored HJR 130 (89R): right to abortion "on or before 24 weeks post-
--                     fertilization", life/health after; NO on bans
--   KEEP 3 (1) — a primary instrument shows an elective first-trimester framework:
--     Becky Stille    own Nebraska Family Alliance questionnaire endorsing NE's first-trimester window
--                     with medical/rape/incest limits after  (no DB change)
--   DOCUMENTED BLANK (31) — no primary instrument places a specific chair (HB 44/SB 31 only, a lone
--   anti-ban vote, party default, or secondary sources). Answer removed; context rewritten as a dated
--   blank naming what was checked. (List: see section 4.)
--
-- Expected end state (abortion, all seasons — only Season 1 carries answers today):
--   chair counts 1=526, 2=629, 3=56, 4=502, 5=198 (was 522/627/100/495/198);
--   13 rows re-valued (7->4, 4->1, 2->2), 31 answer rows removed, 1 kept at 3.

BEGIN;

-- ── 0. Preconditions (structural only, so the migration is idempotent) ───────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='af2fdfd6-02c4-49df-b09c-cf8536f4773f' AND topic_key='abortion') THEN
    RAISE EXCEPTION 'precondition: abortion topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions
                 WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
                   AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
                   AND topic_revision_id='dab46e5c-628a-4360-ad1d-3aaba61768f0') THEN
    RAISE EXCEPTION 'precondition: Season 1 abortion pin is not revision 1 (dab46e5c)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id='085feb9c-f157-4dae-bfd0-7b2736c5d87c'
                   AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
                   AND revision=5 AND version=1 AND status='published' AND is_current) THEN
    RAISE EXCEPTION 'precondition: clarifying revision 5 (085feb9c) is not the current published revision';
  END IF;
END $$;

-- ── 1. MOVE + RESEAT: 13 rows re-valued, each context rewritten to argue THAT chair + name the ─────
--        instrument. reseat.new_value is 4 (ban+exceptions), 1 (broad access) or 2 (viability line).
CREATE TEMP TABLE ab_reseat(pid uuid, new_value int, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO ab_reseat(pid, new_value, reasoning, sources) VALUES
-- MOVE 3 -> 4
('01d02684-5189-4b52-9d38-e7827b4d6b42', 4,
 $r$Rep. Charlie Geren cast recorded floor votes FOR the abortion ban itself: in the 87th Legislature he voted Yea on SB 8, the Texas Heartbeat Act (House Journal 5/6/2021, Record 784, 83-64), and Yea on HB 1280, the Human Life Protection Act trigger ban (Record 793, 81-61). He also co-authored HB 44 (89R), which adds a life-of-mother medical exception to that ban. Backing the ban while supporting only medical exceptions is a ban-with-exceptions position — chair 4 (ban except rape, incest, or a serious risk to the mother's life) — not chair 3, which requires allowing elective abortion during the first trimester.$r$,
 ARRAY['https://journals.house.texas.gov/hjrnl/87r/pdf/87RDAY41FINAL.PDF','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB44']::text[]),
('b01f30e9-0c17-4d59-af5f-a90c176b133d', 4,
 $r$Rep. Drew Darby voted Yea on SB 8, the Texas Heartbeat Act (House Journal 5/6/2021, Record 784), and Yea on HB 1280, the Human Life Protection Act trigger ban (Record 793), and co-authored HB 1806 (89R), which bars a governmental entity from providing logistical support for procuring an abortion. Backing the ban and its enforcement, while HB 44 (89R) supplies only a life-of-mother exception, is a ban-with-exceptions position — chair 4, not the elective-first-trimester chair 3.$r$,
 ARRAY['https://journals.house.texas.gov/hjrnl/87r/pdf/87RDAY41FINAL.PDF','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1806']::text[]),
('b5f2f8c9-13ab-4e15-82dd-dbecb6466084', 4,
 $r$Rep. Keith Bell ("Bell, K." in the record) voted Yea on SB 8, the Texas Heartbeat Act (House Journal 5/6/2021, Record 784), and Yea on HB 1280, the Human Life Protection Act trigger ban (Record 793), and co-authored HB 1806 (89R) barring governmental logistical support for procuring an abortion. Backing the ban itself, with only a life-of-mother exception (HB 44, 89R), is a ban-with-exceptions position — chair 4, not the elective-first-trimester chair 3.$r$,
 ARRAY['https://journals.house.texas.gov/hjrnl/87r/pdf/87RDAY41FINAL.PDF','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1806']::text[]),
('02288122-6afb-46c4-ae9f-a712152b1a73', 4,
 $r$Rep. Lacey Hull voted Yea on SB 8, the Texas Heartbeat Act (House Journal 5/6/2021, Record 784), and Yea on HB 1280, the Human Life Protection Act trigger ban (Record 793), and co-authored HB 1806 (89R) barring governmental logistical support for procuring an abortion. Backing the ban itself, with only a life-of-mother exception (HB 44, 89R), is a ban-with-exceptions position — chair 4, not the elective-first-trimester chair 3.$r$,
 ARRAY['https://journals.house.texas.gov/hjrnl/87r/pdf/87RDAY41FINAL.PDF','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1806']::text[]),
('6121f45c-3508-43a7-a36e-871901303d73', 4,
 $r$Rep. Mano DeAyala took office in 2023 and so cast no vote on the 2021 bans, but he co-authored HB 1806 (89R), which bars a governmental entity from providing logistical support for procuring an abortion — a position incompatible with any elective-access chair — while co-authoring HB 44 (89R), the life-of-mother medical exception, which rules out a no-exceptions stance. Together these place him at chair 4 (ban except for medical/rape/incest cases), not the elective-first-trimester chair 3.$r$,
 ARRAY['https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=HB1806','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB44']::text[]),
('002f4446-75be-4860-935e-3cb65ce296fb', 4,
 $r$Rep. Stan Gerdes states on his own campaign site that he is "unapologetically pro-life," that "Texas has led the nation with the Heartbeat Bill and the Trigger Ban on abortion," and that he "will always stand against efforts to weaken these protections." Endorsing the Heartbeat Act (SB 8) and the Human Life Protection Act trigger ban, while co-authoring HB 44 (89R) for the life-of-mother exception, is a ban-with-exceptions position — chair 4, not the elective-first-trimester chair 3.$r$,
 ARRAY['https://www.stangerdes.com/issues','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB44']::text[]),
('df2b0dba-63d7-4f18-b713-7cc0594ec61d', 4,
 $r$Rep. Janie Lopez states in her own iVoterGuide candidate questionnaire that "Abortion should not be allowed," and publicly describes herself as "100%, unapologetically pro-life," pledging to "shut down abortion clinics"; she also sponsored a bill restricting public funding for logistical support to obtain an abortion. She co-authored HB 44 (89R), which supplies the life-of-mother medical exception. Backing the ban with that exception is a ban-with-exceptions position — chair 4, not the elective-first-trimester chair 3.$r$,
 ARRAY['https://ivoterguide.com/candidate/60693/race/3782/election/871','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB44']::text[]),
-- RESEAT 3 -> 1 (broad access)
('47823046-7dea-4a4f-a11b-0c5890539891', 1,
 $r$Sen. C. Anthony Muse cast a recorded Yea vote on Maryland SB 798 (2023), the "Declaration of Rights — Right to Reproductive Freedom" constitutional amendment (Senate third reading, 3/14/2023, Record SEQ 418, 32-15), which enshrines an individual right to reproductive freedom, including the right to end a pregnancy, with no gestational limit. Voting to codify a broad, unrestricted right places him at chair 1 (abortion broadly legal, minimal restrictions), not chair 3. (This supersedes a prior seating that assumed a conservative-pastor crossover; the recorded vote is to the contrary.)$r$,
 ARRAY['https://mgaleg.maryland.gov/2023RS/votes/senate/0418.pdf','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB0798?ys=2023RS']::text[]),
('f39b0865-c923-428a-b940-09138c09e4e8', 1,
 $r$Rep. Vikki Goodwin authored HB 2251 (89R), "relating to exceptions to and the repeal of certain laws prohibiting abortion," and HJR 33 (89R), a proposed constitutional amendment establishing a right to personal reproductive autonomy; she also voted No on both 2021 bans (SB 8, Record 784; HB 1280, Record 793). Authoring the outright repeal of Texas's abortion prohibitions, with no gestational limit, places her at chair 1 (broadly legal, opposes bans), not the elective-first-trimester chair 3.$r$,
 ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2251','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HJR33']::text[]),
('5b64f3b4-1ec1-4247-9ff3-9e7043be21d6', 1,
 $r$Rep. Gene Wu committed on his own public account (January 2024) to "assisting any of my constituents who desperately need to leave the state to exercise the right to have control over their own bodies and have a safe and legal abortion," and voted No on SB 8 (Record 784), HB 1280 (Record 793) and the 2021 medication-abortion ban. Supporting safe and legal abortion as a matter of bodily autonomy, with no gestational limit, places him at chair 1 (broadly legal), not the elective-first-trimester chair 3.$r$,
 ARRAY['https://journals.house.texas.gov/hjrnl/87r/pdf/87RDAY41FINAL.PDF','https://choicetracker.org/tx/people/gene-wu/88473600']::text[]),
-- Venton Jones: seated on his own campaign platform (a valid primary instrument per the citation bar —
-- "a campaign site counts as their own statement"). audit-chair-evidence.mjs --csv flags this row as a
-- lexical false-negative because a platform citation names no bill/act/vote token; the evidence was read
-- and is quoted below. The regex is left unwidened (per CLAUDE.md), and that gate is not in CI.
('e8058f2b-c68a-474b-b9fe-df4d2d22545b', 1,
 $r$Rep. Venton Jones commits on his own campaign platform to "restore abortion access and funding for reproductive healthcare." A pledge to restore access and to fund abortion is the defining feature of chair 1 (broadly legal, may fund it), not the elective-first-trimester chair 3. He took office in 2023 and so cast no vote on the 2021 bans; his own campaign platform is the placing instrument.$r$,
 ARRAY['https://www.ventonfor100.com/platform']::text[]),
-- RESEAT 3 -> 2 (viability-type line)
('f6570c10-effb-41e1-b559-ef9ca41a2bf1', 2,
 $r$Rep. Ana Hernandez, in her own statement on the Dobbs decision (June 2022), condemned the Court for having "rescinded the fundamental Constitutional right to abortion" and pledged to "remain steadfast in our pursuit of reproductive justice"; she also voted No on SB 8 (Record 784) and HB 1280 (Record 793). Seeking to restore the pre-Dobbs constitutional framework — elective abortion up to viability, with limits after — places her at chair 2 (legal with a viability-type line), not the first-trimester-only chair 3.$r$,
 ARRAY['https://choicetracker.org/tx/people/ana-hernandez/88866816','https://journals.house.texas.gov/hjrnl/87r/pdf/87RDAY41FINAL.PDF']::text[]),
('2be64a58-ae2c-4eee-b80d-6e673ef774bd', 2,
 $r$Rep. John Bucy III authored HJR 130 (89R), a proposed constitutional amendment establishing the right to "obtain an abortion on or before 24 weeks post-fertilization" and, after that, an abortion "necessary to preserve the life or health" of the pregnant person; he also voted No on SB 8 (Record 784) and HB 1280 (Record 793). Setting an explicit elective right up to a 24-week (viability-type) line places him at chair 2, not the first-trimester-only chair 3.$r$,
 ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HJR130','https://journals.house.texas.gov/hjrnl/87r/pdf/87RDAY41FINAL.PDF']::text[]);

UPDATE inform.politician_answers a
   SET value = r.new_value, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
  FROM ab_reseat r
 WHERE a.politician_id = r.pid
   AND a.topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND a.season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
   AND a.value = 3;

UPDATE inform.politician_context c
   SET reasoning = r.reasoning, sources = r.sources,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
  FROM ab_reseat r
 WHERE c.politician_id = r.pid
   AND c.topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND c.season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

-- ── 2. KEEP: Becky Stille stays at chair 3 (own NE Family Alliance questionnaire endorses Nebraska's ─
--        elective first-trimester window with medical/rape/incest limits after). No DB change; the
--        post-verify gate below confirms she is still seated at value 3.

-- ── 3. BLANK: 31 rows lose their answer; context rewritten as a dated documented blank naming what ──
--        was checked and why it fails to place a chair. Leading "Researched 2026-08-30" is TRUE (each
--        record was read this pass) and satisfies the ORPHAN_CONTEXT carve-out. Sources are left as
--        the trail of what was checked.
CREATE TEMP TABLE ab_blank(pid uuid, reasoning text) ON COMMIT DROP;
INSERT INTO ab_blank(pid, reasoning) VALUES
('f920022b-4aa0-47ae-a5ae-c2edf3e17044',
 $r$Researched 2026-08-30 — Rep. John McQueeney's chair-3 seating rested on HB 44 (89R) co-authorship; he was not seated for the 2021 ban votes, and his campaign site offers only a self-described "pro-life" label with no ban, exception, or elective-window detail. Under the CA_0033 primary-source bar this is direction only, not a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('786ac925-59d3-40e3-a9ce-b63a54f4caf4',
 $r$Researched 2026-08-30 — Rep. Marc LaHood's chair-3 seating rested on HB 44 (89R) co-authorship; his campaign site is a generic "pro-life and pro-family" values statement with no ban, exception, or elective-window language. That is direction only, not a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('1c90dfec-8203-4c1c-9158-48b775862109',
 $r$Researched 2026-08-30 — Rep. Morgan Meyer's chair-3 seating rested only on HB 44 / SB 31 (89R) co-authorship, the bipartisan medical-exception clarification; his campaign issues page contains no abortion content and no other primary instrument places a chair. Left blank pending a primary-sourced re-audit.$r$),
('099c7880-e909-4874-a257-cc8ca54ca7bd',
 $r$Researched 2026-08-30 — Rep. Richard Hayes's chair-3 seating rested on HB 44 (89R) co-authorship; his campaign site names only a one-line "protect precious unborn life" priority with no ban or exception detail. That is direction only, not a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('47cdb7af-9fff-487a-a6d1-23c66d21a414',
 $r$Researched 2026-08-30 — Rep. Stan Lambert's chair-3 seating rested on HB 44 / SB 31 (89R) co-authorship, the medical-exception clarification; his campaign site was unreachable and no other statement of his own could be retrieved. No primary instrument places a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('37be7b0c-64a5-426d-be36-3272ffc9675b',
 $r$Researched 2026-08-30 — Rep. Aicha Davis's chair-3 seating rested only on HB 44 / SB 31 (89R) co-authorship, the bipartisan Life of the Mother Act; that medical-emergency clarification establishes only direction, not a chair, and no other primary instrument (own bill, vote, or statement) places one. Left blank pending a primary-sourced re-audit.$r$),
('4750d905-2ccc-4eaf-9a69-f5f20ef8b18f',
 $r$Researched 2026-08-30 — Rep. Alma Allen's chair-3 seating rested on HB 44 / SB 31 (89R) co-authorship plus a vote against SB 8; a lone anti-ban vote and the medical-exception bill establish direction only, not a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('60e2bada-4104-47af-b4d7-93662e401543',
 $r$Researched 2026-08-30 — Rep. Charlene Ward Johnson's chair-3 seating rested on joint-authorship of HB 44 (89R); the only access-specific source was an advocacy voter-guide line that could not be confirmed as her own words. HB 44 places no chair, so no primary instrument places one. Left blank pending a primary-sourced re-audit.$r$),
('d45bbf56-7e43-4932-b536-fd73173eb295',
 $r$Researched 2026-08-30 — Rep. Claudia Ordaz's chair-3 seating rested on HB 44 / SB 31 (89R) co-authorship; her own authored bills (HB 916, HB 220) concern contraception and emergency contraception, not abortion legality. No primary instrument places a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('3a310d29-093f-417b-a23f-885aa3658b12',
 $r$Researched 2026-08-30 — Rep. Diego Bernal's chair-3 seating rested on SB 31 (89R) co-sponsorship plus a vote against SB 8; the medical-exception bill and a lone anti-ban vote establish direction only, not a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('155a62d8-9e8e-4231-94dc-823b9f15b30b',
 $r$Researched 2026-08-30 — Rep. Eddie Morales's chair-3 seating rested only on HB 44 (89R) co-authorship; his campaign site and bill record show no abortion position of his own. HB 44 places no chair. Left blank pending a primary-sourced re-audit.$r$),
('c1914284-9aee-44f4-8b7f-a833d8f392e7',
 $r$Researched 2026-08-30 — Rep. Elizabeth Campos's chair-3 seating rested on HB 44 / SB 31 (89R) (her site cites only the Life of the Mother Act) plus a vote against SB 8; that is direction only, not a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('112dd21d-c4ea-4299-91a4-46508b74fdca',
 $r$Researched 2026-08-30 — Rep. Erin Gámez's chair-3 seating rested on a Yes vote for SB 31 (89R), the medical-exception bill; she was not seated for the 2021 ban votes and her campaign site addresses only postpartum Medicaid. No primary instrument places a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('25183d7a-9300-4065-8d42-941ae826ca91',
 $r$Researched 2026-08-30 — Rep. Hubert Vo's chair-3 seating rested on HB 44 (89R) co-authorship plus a vote against HB 1280; a lone anti-ban vote and the medical-exception bill establish direction only, not a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('e36f4bc1-4896-48cb-8ae7-39e1f742ace3',
 $r$Researched 2026-08-30 — Rep. Jessica González's chair-3 seating rested only on HB 44 (89R) co-authorship; her 89R authored, co-authored and co-sponsored record and her campaign site contain no other abortion instrument. Left blank pending a primary-sourced re-audit.$r$),
('819c3c06-c958-4e98-bc60-da91e3fb5c24',
 $r$Researched 2026-08-30 — Rep. Joe Moody's chair-3 seating rested only on HB 44 (89R) co-authorship; no authored abortion bill, floor statement, or campaign position of his own was found. Left blank pending a primary-sourced re-audit.$r$),
('f5f63005-94a6-4170-b120-a421ea5a8f3b',
 $r$Researched 2026-08-30 — Rep. Jon Rosenthal's chair-3 seating rested on HB 44 (89R) co-authorship plus a vote against the 2021 bans; a co-authored medical-exception bill and a lone anti-ban vote establish direction only, not a specific chair, and no other primary instrument of his own was accessible. Left blank pending a primary-sourced re-audit.$r$),
('d62f0017-3d27-43f0-8908-781f3c9e5050',
 $r$Researched 2026-08-30 — Rep. Lauren Ashley Simmons's chair-3 seating rested on HB 44 (89R) co-authorship; her own joint-authored HB 5237 (89R) shields lawful abortions from wrongful-death liability — a pro-access DIRECTION, but it states no elective line and cannot distinguish a chair. Left blank pending a primary-sourced re-audit.$r$),
('08e96b22-0cdc-48bb-b94a-ef4c54491f98',
 $r$Researched 2026-08-30 — Rep. Linda García's chair-3 seating rested only on HB 44 (89R) co-authorship; her 89R authored and co-authored record contains no other abortion instrument and she has no statement of her own placing a chair. Left blank pending a primary-sourced re-audit.$r$),
('76fb2373-43c5-4f18-9e0f-18da31e0f863',
 $r$Researched 2026-08-30 — Rep. Richard Raymond's chair-3 seating rested on HB 44 (89R) co-authorship; his 89R authored, co-authored and sponsored record contains no abortion bill and no statement of his own places a chair. Left blank pending a primary-sourced re-audit.$r$),
('6577418b-49cc-4a03-a194-97020e0e8c9a',
 $r$Researched 2026-08-30 — Rep. Robert Guerra's chair-3 seating rested on HB 44 (89R) co-authorship plus a vote against the 2021 bans; his 89R bill record and campaign site are otherwise silent on abortion, so only direction is shown, not a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('6bdea3fd-5a3f-4d43-a0cc-9f4c7373c269',
 $r$Researched 2026-08-30 — Rep. Vincent Perez's chair-3 seating rested on HB 44 (89R) co-authorship; his 89R solo-authored bills are silent on abortion and no statement of his own places a chair. Left blank pending a primary-sourced re-audit.$r$),
('6d13d033-f970-4356-8cce-73d81f342dc8',
 $r$Researched 2026-08-30 — Rep. Christian Manuel's chair-3 seating was a party default; he is not a co-author of HB 44 / SB 31, authored no abortion bill, and no floor vote or statement of his own addresses abortion. No primary instrument places a chair. Left blank pending a primary-sourced re-audit.$r$),
('b5e9a6f8-e768-402e-aff5-77dc22e68115',
 $r$Researched 2026-08-30 — Rep. Christina Morales's chair-3 seating was a party default; she is not a co-author of HB 44 / SB 31, authored no abortion bill, and no statement of her own addresses abortion. No primary instrument places a chair. Left blank pending a primary-sourced re-audit.$r$),
('9c972a56-0084-483d-a4f2-8b42a823e58a',
 $r$Researched 2026-08-30 — Rep. Harold Dutton Jr.'s chair-3 seating was a party default; he is not a co-author of HB 44 / SB 31, and none of his authored bills or statements address abortion. No primary instrument places a chair. Left blank pending a primary-sourced re-audit.$r$),
('42bff283-c977-43f1-9d54-a06131dc5eac',
 $r$Researched 2026-08-30 — Rep. David Valadao's own instruments show a pro-life direction with support for rape/incest/life exceptions and state deference: he declined to co-sponsor the 118th Congress Life at Conception Act, citing missing exceptions and state authority, and his only ban vote (H.R. 36, a 20-week limit) permits elective abortion before 20 weeks. None backs a near-total ban with no elective window, so chair 4 is not evidenced and chair 3 is not established. Left blank pending a primary-sourced re-audit.$r$),
('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
 $r$Researched 2026-08-30 — Mr. Don Tracy's chair-3 seating rested on a states-decide/federalism position in his own words ("Illinois's abortion laws are different than Alabama... that's the way it should be") plus support for the Hyde funding limit; he accepts both permissive and restrictive state regimes and offers no framework of his own. No primary instrument places a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('48f9e64c-ff9a-4a2e-8d01-e3d85b7fc00e',
 $r$Researched 2026-08-30 — Mr. Elias Henry Montgomery's own platform rejects the criminal-ban mechanism ("true progress does not come from... a criminal ban") while pledging to protect only listed exceptions and to reduce abortion through social support; it never affirms an elective right or a first-trimester window. It rules out chairs 4-5 but establishes no specific access chair. Left blank pending a primary-sourced re-audit.$r$),
('02706ab4-75fc-4bbd-ae1e-b879c0955d3f',
 $r$Researched 2026-08-30 — Rep. Max L. Miller's chair-3 seating rested on secondary sources only (interest-group scorecards and a 2022 characterization of state-deference and opposition to a 15-week federal ban); no primary instrument of his own places a specific chair. Left blank pending a primary-sourced re-audit.$r$),
('7c0d3bdd-a363-4d97-93a9-67034c6a0ead',
 $r$Researched 2026-08-30 — Councilmember Monica Rodriguez's only connection to the topic is her absence from the Los Angeles City Council's 11-0 post-Dobbs reproductive-rights resolution (CF 22-0002-S73); an absence is not a chair-placing instrument, and no statement, motion, or vote of her own states an abortion position. Left blank pending a primary-sourced re-audit.$r$),
('b6c3620e-1ac1-460c-acb4-74854d59b334',
 $r$Researched 2026-08-30 — Mr. Seth Bodnar's campaign site expresses only a general "freedom and privacy" / anti-government-intrusion direction with no Roe/viability, trimester, ban, or exception detail. That is direction only, not a specific chair. Left blank pending a primary-sourced re-audit.$r$);

DELETE FROM inform.politician_answers a
 USING ab_blank b
 WHERE a.politician_id = b.pid
   AND a.topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND a.season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

UPDATE inform.politician_context c
   SET reasoning = b.reasoning,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
  FROM ab_blank b
 WHERE c.politician_id = b.pid
   AND c.topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND c.season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

-- @context-decision: rewritten-as-blank — the abortion topic applies to all 31 people and each record
-- WAS read on 2026-08-30; none carries a primary instrument that places a specific chair (HB 44/SB 31
-- co-authorship, a lone anti-ban vote, party default, or secondary sources only), so each context is a
-- documented blank naming what was checked. No answer row remains for these pairs.

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate, applied to the pairs this migration
-- blanked. Regexes kept character-identical to the gate.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM ab_blank t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND pc.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
   WHERE coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- ── 4. Post-verify gate (row-specific + distribution, idempotent) ─────────────────────────────────
DO $$
DECLARE
  tid uuid := 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  sid uuid := '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  c1 int; c2 int; c3 int; c4 int; c5 int; nmoved int; still int; nblank int; nkeep int;
BEGIN
  -- 7 moves seated at 4, 4 reseated at 1, 2 reseated at 2 (13 rows, none left at 3)
  SELECT count(*) INTO nmoved
    FROM ab_reseat r JOIN inform.politician_answers a
      ON a.politician_id=r.pid AND a.topic_id=tid AND a.season_id=sid AND a.value=r.new_value;
  IF nmoved <> 13 THEN RAISE EXCEPTION 'verify: expected 13 re-valued rows, found %', nmoved; END IF;
  IF EXISTS (SELECT 1 FROM ab_reseat r JOIN inform.politician_answers a
              ON a.politician_id=r.pid AND a.topic_id=tid AND a.season_id=sid WHERE a.value=3) THEN
    RAISE EXCEPTION 'verify: a re-valued row is still at chair 3';
  END IF;
  -- 31 blanked rows have no answer row
  SELECT count(*) INTO still FROM ab_blank b
    JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=tid AND a.season_id=sid;
  IF still <> 0 THEN RAISE EXCEPTION 'verify: % blanked pair(s) still have an answer row', still; END IF;
  -- their context is a documented blank (leading "Researched")
  SELECT count(*) INTO nblank FROM ab_blank b
    JOIN inform.politician_context pc ON pc.politician_id=b.pid AND pc.topic_id=tid AND pc.season_id=sid
   WHERE pc.reasoning ~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}';
  IF nblank <> 31 THEN RAISE EXCEPTION 'verify: expected 31 documented-blank contexts, found %', nblank; END IF;
  -- Becky Stille kept at chair 3
  SELECT count(*) INTO nkeep FROM inform.politician_answers
   WHERE politician_id='62b87d95-e02e-43de-902e-ad0b1328ab82' AND topic_id=tid AND season_id=sid AND value=3;
  IF nkeep <> 1 THEN RAISE EXCEPTION 'verify: Becky Stille is not still seated at chair 3 (found %)', nkeep; END IF;
  -- Chair distribution (topic-wide; only Season 1 carries answers today)
  SELECT count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2), count(*) FILTER (WHERE value=3),
         count(*) FILTER (WHERE value=4), count(*) FILTER (WHERE value=5)
    INTO c1,c2,c3,c4,c5 FROM inform.politician_answers WHERE topic_id=tid;
  IF (c1,c2,c3,c4,c5) <> (526,629,56,502,198) THEN
    RAISE EXCEPTION 'verify: chair counts are %/%/%/%/% (expected 526/629/56/502/198)', c1,c2,c3,c4,c5;
  END IF;
END $$;

COMMIT;
