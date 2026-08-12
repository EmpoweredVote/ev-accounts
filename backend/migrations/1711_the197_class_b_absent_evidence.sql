-- 1711_the197_class_b_absent_evidence.sql
-- "The 197", class B — rows whose OWN reasoning declares that no evidence was found.
--
-- 🔑 THIS LOOKED LIKE THE CLEANEST RETIREMENT CLASS IN THE SET, because the author had already
-- searched and reported the absence. Searching independently moved 3 of 14 rows OUT of it.
-- Retirement is what is left after looking, not the first move.
--
-- RE-SOURCED (3): Hyde-Smith and Wicker have recorded Senate votes on exactly the subjects
-- their rows said nothing could be found for. Hyde-Smith's row said her record "suggests
-- opposition to DISCLOSE Act" — she voted against cloture on it (S.4822, 117-2 roll 346).
--
-- RETIRED (9): chair rests on a party, caucus or district prior plus a declared absence, and
-- an independent search of the member's own record found nothing on topic. Per the standing
-- rule, where no source supports a chair the answer is NO STANCE — not a weaker chair.
-- ⚠ The standard applied is VERIFIED ABSENT, never UNSURE. Rows that were merely hard to check
-- are left alone, below.
--
-- ⚠ NOT RETIRED, deliberately:
--   · Joyce / Medicare — real votes exist (IRA nay, OBBBA aye) but they are omnibus votes that
--     pin no chair and if anything cut AGAINST the stored chair 3. A partial sample is not a search.
--   · Ron Reynolds / Climate — capitol.texas.gov redirects to its search form, so his bill record
--     could not be read at all. UNASSESSED IS NOT VERIFIED-ABSENT.
--   · Carrie Isaac / Civil Rights — "critical race theory" IS on her cited page, in prose. The
--     lexicon missed it because "race" is not "racial". A near-miss stem, not an absent topic.
--   · Gimenez / Reproductive Rights — its affirmative claim cites ISideWith, which is not in the
--     sources array. A CITATION GAP needing re-sourcing, not an absent stance.
--   · Paxton / Medicare, McClain / Same-Sex Marriage — their "no evidence" clause NARROWS a chair
--     on a row already carried by real evidence. The opposite of this defect, and the reason the
--     detector keys on the row's ONLY claim being an absence rather than on the phrase.
--
-- Nobody is emptied: David Schweikert 17->16, Derek Tran 29->26, Elissa Slotkin 24->23, Kelly A. Dooner 22->18.
-- Rollback (the only surviving copy of the retired rows): data/stance-retirement/2026-08-12-the-197-class-b-rollback.json
BEGIN;

CREATE TEMP TABLE classb_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

-- ── RE-SOURCE ──────────────────────────────────────────────────────────────────────────────
-- Cindy Hyde-Smith / Campaign Finance Reform
--   stored text said her record "suggests opposition to DISCLOSE Act" — she voted against cloture on it
UPDATE inform.politician_context SET sources = ARRAY['https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=117&session=2&vote=00346','https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=117&session=1&vote=00420']::text[], reasoning = 'Voted NAY on cloture to proceed to S.4822, the DISCLOSE Act, on 22 September 2022 (Senate roll call 346, 49-49); the bill would have added disclosure requirements for corporate and dark-money political spending. Also voted NAY on cloture to proceed to S.2747, the Freedom to Vote Act, on 20 October 2021 (roll call 420, 49-51), which carried further political-spending disclosure provisions.'
WHERE politician_id = '4d83f985-9248-4905-a9b6-5742e2df77a8'::uuid AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid;

-- Roger Wicker / Campaign Finance Reform
--   stored text said "No bill sponsorships or floor statements … were found"; two recorded votes exist
UPDATE inform.politician_context SET sources = ARRAY['https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=117&session=2&vote=00346','https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=117&session=1&vote=00420']::text[], reasoning = 'Voted NAY on cloture to proceed to S.4822, the DISCLOSE Act, on 22 September 2022 (Senate roll call 346, 49-49); the bill would have added disclosure requirements for corporate and dark-money political spending. Also voted NAY on cloture to proceed to S.2747, the Freedom to Vote Act, on 20 October 2021 (roll call 420, 49-51), which carried further political-spending disclosure provisions.'
WHERE politician_id = 'd53cbad2-d166-4f8d-87a2-f7e5ddc7a237'::uuid AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid;

-- Cindy Hyde-Smith / State Redistricting and Gerrymandering
--   omnibus votes — they evidence opposition to mandated commissions, and the reasoning says so rather than over-claiming
UPDATE inform.politician_context SET sources = ARRAY['https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=117&session=1&vote=00246','https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=117&session=1&vote=00358']::text[], reasoning = 'Voted NAY on cloture to proceed to S.2093, the For the People Act, on 22 June 2021 (Senate roll call 246, 50-50), and NAY on the motion to discharge S.1 on 11 August 2021 (roll call 358, 50-49). Both bills would have required states to draw congressional districts through independent commissions. These are omnibus voting bills, so the votes show opposition to a federal mandate for independent commissions rather than a stated preference between legislature-drawn maps with court oversight and unrestricted legislative control.'
WHERE politician_id = '4d83f985-9248-4905-a9b6-5742e2df77a8'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid;

-- ── RETIRE ─────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE _retire_classb (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_classb (politician_id, topic_id) VALUES
  ('17e59190-17e2-4a90-8353-b5ea8d083480', '683c8084-2281-4920-a07c-18439b2dd413'),  -- David Schweikert: United States Tariff Policy
  ('b7612f49-c914-4ea7-a6da-559d71f313c2', '00b95a6a-75db-4521-b523-3326bba938de'),  -- Derek Tran: School Vouchers & Public Education Funding
  ('b7612f49-c914-4ea7-a6da-559d71f313c2', '4559b513-0fd8-4ed1-babd-f3b554162f40'),  -- Derek Tran: Data Center Development & Energy Costs
  ('b7612f49-c914-4ea7-a6da-559d71f313c2', '666bf03d-81fc-4138-ab15-69ae734c9023'),  -- Derek Tran: Artificial Intelligence Oversight
  ('ebe10065-0025-46e5-897e-7a81e4c77ecf', '666bf03d-81fc-4138-ab15-69ae734c9023'),  -- Elissa Slotkin: Artificial Intelligence Oversight
  ('247cf8e5-426a-4104-9027-6a2a0b1b61c9', '6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Kelly A. Dooner: Religious Freedom
  ('247cf8e5-426a-4104-9027-6a2a0b1b61c9', '92730f69-ae57-401c-8ad1-2d07834a895d'),  -- Kelly A. Dooner: Campaign Finance Reform
  ('247cf8e5-426a-4104-9027-6a2a0b1b61c9', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'),  -- Kelly A. Dooner: Same-Sex Marriage
  ('247cf8e5-426a-4104-9027-6a2a0b1b61c9', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f');  -- Kelly A. Dooner: Reproductive Rights and Abortion Access

-- David Schweikert / United States Tariff Policy:
--   chair 1 is "eliminate all tariffs and pursue completely free trade" — the most absolute position on the
--   scale — and rested on "Ballotpedia and Wikipedia document no support for broad tariffs". The cited page
--   contains no occurrence of "tariff"; its only "trade" hit is the word "trademark" in the Wikipedia footer.
--   No tariff vote appears in the Clerk indexes for 2019, 2022, 2025 or 2026; his one trade vote is USMCA
--   (385-41), near-unanimous and not tariff elimination.
--
-- Derek Tran / School Vouchers & Public Education Funding:
--   the row opens "No evidence of Derek Tran supporting school voucher programs was found" and derives the
--   chair from New Democrat Coalition membership. Caucus membership is not a position. No recorded House vote
--   on vouchers or school choice in 2025 or 2026.
--
-- Derek Tran / Data Center Development & Energy Costs:
--   the row opens "No direct statement by Tran on data center policy was found" and derives the chair from
--   Fusion Energy Caucus and New Democrat Coalition membership. No recorded House vote on data centers in
--   2025 or 2026.
--
-- Derek Tran / Artificial Intelligence Oversight:
--   the row states "No specific AI safety bill sponsorship found" and rests on caucus membership plus a
--   subcommittee role. No recorded House vote on artificial intelligence in 2025 or 2026.
--
-- Elissa Slotkin / Artificial Intelligence Oversight:
--   the row states she "has not introduced major AI governance legislation and holds no clear public
--   position", then places her at the midpoint anyway on the basis of a CIA background. Her cited page
--   contains no occurrence of "artificial intelligence" or "algorithm"; no recorded AI vote in 2025 or 2026.
--
-- Kelly A. Dooner / Religious Freedom:
--   the whole row is "Republican with no evidence of restricting religious exemptions" plus national party
--   positions. Her complete 194th General Court record — 49 sponsored and 40 cosponsored bills — contains
--   nothing on religion, faith, conscience or clergy.
--
-- Kelly A. Dooner / Campaign Finance Reform:
--   the whole row is "Republican Assistant Minority Leader with no evidence of support for campaign finance
--   restrictions" plus national party positions. Her 89 bills include one election bill, on uniform treatment
--   of vote-by-mail ballots, which is election administration and says nothing about donations or spending.
--
-- Kelly A. Dooner / Same-Sex Marriage:
--   the row reasons from an absence to a guess — "No evidence of Dooner publicly opposing same-sex marriage …
--   she most likely defers to state-level decisions". Her 89 bills contain nothing on marriage, sexual
--   orientation or gender identity.
--
-- Kelly A. Dooner / Reproductive Rights and Abortion Access:
--   the chair rests on "Republican affiliation and district profile" after stating "No MA legislative record
--   of supporting abortion access". The bills the row does name (S.972-976, S.121-123) are emergency-housing
--   and EBT measures. Her 89 bills contain nothing on abortion, reproduction, pregnancy or contraception.
--

DELETE FROM inform.politician_context c USING _retire_classb r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;
DELETE FROM inform.politician_answers a USING _retire_classb r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- Guard 1: the retired pairs are gone from BOTH tables.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers a JOIN _retire_classb r USING (politician_id, topic_id);
  IF n <> 0 THEN RAISE EXCEPTION 'guard 1 failed: % targeted answer(s) remain', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_context c JOIN _retire_classb r USING (politician_id, topic_id);
  IF n <> 0 THEN RAISE EXCEPTION 'guard 1 failed: % targeted context row(s) remain', n; END IF;
END $$;

-- Guard 2: NOBODY is emptied. A politician at zero answers reads as "we looked and found
-- nothing" — a real finding this pass must never create by accident.
DO $$
DECLARE bad text;
BEGIN
  SELECT string_agg(p.full_name, ', ') INTO bad
  FROM (SELECT DISTINCT politician_id FROM _retire_classb) t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = t.politician_id);
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'guard 2 failed: emptied %', bad; END IF;
END $$;

-- Guard 3: exactly 9 answers and 9 context rows removed, 3 rows re-sourced, no orphans.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record; n int;
BEGIN
  SELECT * INTO snap FROM classb_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF snap.ctx_before - ctx_after <> 9 THEN RAISE EXCEPTION 'guard 3 failed: context moved % -> % (expected -9)', snap.ctx_before, ctx_after; END IF;
  IF snap.ans_before - ans_after <> 9 THEN RAISE EXCEPTION 'guard 3 failed: answers moved % -> % (expected -9)', snap.ans_before, ans_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 3 failed: % orphan answer(s)', orphans; END IF;
  SELECT count(*) INTO n FROM inform.politician_context c
   WHERE (c.politician_id, c.topic_id) IN (('4d83f985-9248-4905-a9b6-5742e2df77a8'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid), ('d53cbad2-d166-4f8d-87a2-f7e5ddc7a237'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid), ('4d83f985-9248-4905-a9b6-5742e2df77a8'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid))
     AND EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%roll_call_vote_cfm.cfm%')
     AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%wikipedia.org%' OR s LIKE '%ballotpedia.org%');
  IF n <> 3 THEN RAISE EXCEPTION 'guard 3 failed: % of 3 re-sourced rows carry a Senate roll call and no encyclopaedia', n; END IF;
  RAISE NOTICE 'class B ok: context %->%, answers %->%, orphans %', snap.ctx_before, ctx_after, snap.ans_before, ans_after, orphans;
END $$;

COMMIT;
