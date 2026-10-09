-- Migration 1916 — the VINTAGE queue: 6 chairs withdrawn and 1 citation repaired, where the row's
-- basis is old enough that it no longer speaks for the person.
--
-- WHERE THIS CAME FROM. Working the absence tier-A queue (mig 1915) turned up 8 rows that PASSED
-- the absence test — real, on-point, attributed positions — and failed a different one: each was
-- held over by the words "no reversal documented" from a filing years or decades old. They were
-- deliberately not blanked in 1915, because staleness is a different defect class from
-- absence-seating. This file works that queue.
--
-- ⚖ THE TEST APPLIED. A vintage row STANDS if the old position is still the person's latest filing
-- and nothing has materially changed. It is WITHDRAWN if (a) something newer contradicts it, or
-- (b) the person's office, party or the surrounding law changed enough that the old filing can no
-- longer be read as current. Standing ruling: THE LATEST FILING GOVERNS.
--
-- 🔑 EVERY SOURCE BELOW WAS FETCHED. Nothing is cited from a search-result summary. That mattered:
-- a search result offered a 48hills article as evidence of an Alan Wong rent-control vote, and
-- fetching it showed the article DOES NOT MENTION HIM. Citing it would have composed a citation of
-- exactly the kind migration 1538 had to retire.
--
-- 6 of 8 failed — a higher rate than the 67% of the main absence queue, which is the argument for
-- having flagged them separately rather than folding them in.

CREATE TEMP TABLE mig1916 (
  politician_id uuid NOT NULL, topic_id uuid NOT NULL, topic_revision_id uuid NOT NULL,
  new_value numeric NOT NULL, reasoning text NOT NULL, sources text[] NOT NULL, who text NOT NULL
) ON COMMIT DROP;

INSERT INTO mig1916 (politician_id, topic_id, topic_revision_id, new_value, reasoning, sources, who)
VALUES
-- Pete Ricketts / same-sex-marriage — was 5 ("make same-sex marriage illegal"), on a 2006 line.
('d01ea902-317a-4a66-b346-8b29a91fcd25','c5ab4eab-702f-49b8-9277-8ea53f3835c6','8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f',0,
 'INTERNAL RECORD - blanked because the basis was superseded and the better evidence picks a band, not a rung. The chair rested on a 2006 campaign line, "marriage is the union of one woman and one man". Fetched 2026-10-09: in March 2015 as Governor he "supports Nebraska''s definition of marriage, despite a federal judge''s ruling overturning it" and said "if the ban on same-sex marriage is to be struck down, it should be changed by the voters" (WNAX). That second clause is rung 3 - let each state decide without federal interference - while supporting the ban is rung 5, so the same statement is consistent with both. Wikipedia''s account of the period adds that he was critical of Obergefell but said the state would comply. Nothing was found from his Senate tenure (January 2023 onward) on this topic. A nineteen-year-old campaign line cannot carry the ladder''s most extreme rung against later evidence that spans two rungs.',
 ARRAY['https://wnax.com/news/180081-ricketts-defends-same-sex-marriage-ban/','https://en.wikipedia.org/wiki/Same-sex_marriage_in_Nebraska']::text[],'Ricketts'),
-- Scott Brown / abortion — was 2; the 2026 filing points the OTHER WAY.
('125c28f8-9419-49a8-85f8-1e6d0d638ae6','af2fdfd6-02c4-49df-b09c-cf8536f4773f','dab46e5c-628a-4360-ad1d-3aaba61768f0',0,
 'INTERNAL RECORD - blanked because the current filing CONTRADICTS the chair. The row rested on 2012-2014 material describing him as pro-choice and calling Roe settled law, seating "legal and accessible through the second trimester". Fetched 2026-10-09: his Citizens Count profile for the 2026 New Hampshire Senate race records him AGAINST a federal right to abortion before 24 weeks, and on a federal abortion ban saying "As President Trump has rightly stated, this is a matter that should be left to the states to decide" (Citizens Count Issue Survey, 2026). That is a position about WHICH GOVERNMENT DECIDES, which this ladder does not grade, and it is incompatible with the rung the row carried. Not re-seated: deferring to the states locates him nowhere on a gestational-limit ladder.',
 ARRAY['https://www.citizenscount.org/candidate/scott-brown/running']::text[],'Brown'),
-- Brian L Bengs / ukraine-support — was 2, on a 2022 campaign, since changed party.
('3c666783-8d3b-45a8-9b67-169c17577825','24e9212c-b011-422a-865c-093e35050901','107d180d-a949-4a42-a250-54f0a7683be0',0,
 'INTERNAL RECORD - blanked on currency, not accuracy. The 2022 statement is real: as a Democratic Senate candidate he backed providing aircraft to Ukraine. Since then he has changed affiliation and is running as an INDEPENDENT in 2026, and four years of the war have passed. The row itself said the dated evidence was used because "no updated 2026 statement was found", and a search on 2026-10-09 found none either. A position taken under a different party label, about a conflict whose terms have moved, is not evidence of where he sits now.',
 ARRAY[]::text[],'Bengs'),
-- Keith B. Goodenough / civil-rights — was 2, on a 2008 Democratic-era record; 2026 line differs.
('27e19bcf-9501-48b5-bc08-34097fcefc70','0bc588c6-39e1-4084-b5de-cac909b8b762','2010cab0-1968-4f24-b74d-ca47c2f90165',0,
 'INTERNAL RECORD - blanked because a newer filing points elsewhere and the party has changed. The chair rested on a 2008 OnTheIssues entry from his DEMOCRATIC state Senate tenure supporting protection of sexual orientation under civil rights law, seating "strengthen civil rights enforcement and address systemic discrimination". In 2026 he ran in the REPUBLICAN primary for Wyoming''s at-large House seat, and his 2026 candidate guide entry states on civil rights only: "No discrimination, but the best person should get the job." That is an equal-treatment framing rather than strengthened enforcement against systemic discrimination, and it does not clearly seat a rung of its own.',
 ARRAY['https://projects.wyofile.com/election-guide-2026/candidates/goodenough-keith/']::text[],'Goodenough civil-rights'),
-- Keith B. Goodenough / school-vouchers — was 1, same 2008 Democratic-era basis, nothing current.
('27e19bcf-9501-48b5-bc08-34097fcefc70','00b95a6a-75db-4521-b523-3326bba938de','88858826-90c0-41c9-a3a4-1d9f5b8c5307',0,
 'INTERNAL RECORD - blanked on currency. The chair rested on an OnTheIssues entry of June 2008 recording him as opposing school choice via vouchers, from his DEMOCRATIC state Senate tenure. He ran in the 2026 REPUBLICAN primary for Wyoming''s at-large House seat; no 2026 position on vouchers or education funding was found on 2026-10-09. An eighteen-year-old record from the other party is not a current position.',
 ARRAY['https://projects.wyofile.com/election-guide-2026/candidates/goodenough-keith/']::text[],'Goodenough school-vouchers'),
-- Alan Wong / rent-regulation — was 2, on a 2020 CITY COLLEGE platform.
('6273727a-26e0-495d-9fda-f827b88029b3','c308e8e8-caac-44f5-ab04-dbfecf40bbe2','6fa44a68-8006-48e9-b562-6b5e61d58693',0,
 'INTERNAL RECORD - blanked because the basis was a campaign for a DIFFERENT OFFICE and is no longer current. The chair rested on his 2020 City College board platform backing expanded rent control, carried forward by "no public reversal documented" - and the row itself conceded that "his overall ideological shift toward the center on other issues leaves some uncertainty". Fetched 2026-10-09: he was sworn in as District 4 Supervisor and about 24 hours later, on 1 December 2025, voted for Mayor Lurie''s Family Zoning Plan. His vote on the amendment to exempt all rent-controlled units from demolition is NOT recorded, so nothing here re-seats him - but a City College platform is not a statement of a sitting supervisor''s rent-regulation position. 🔴 A search result offered a 48hills rent-control article as evidence about him; fetching it showed it does not mention him at all, and it is deliberately NOT cited.',
 ARRAY['https://sf.gazetteer.co/welcome-to-city-hall-alan-wong']::text[],'Wong'),
-- Tim Walz / campaign-finance — REPAIR, not a blank. Chair stays at 2; the citation moves forward.
('d9b4d757-aa43-458d-9ecc-973338bceee4','92730f69-ae57-401c-8ad1-2d07834a895d','ae53ba29-79eb-420f-aac6-ec99f8031ec6',2,
 'Co-sponsored the 2012 DISCLOSE Act, "requiring full disclosure of independent campaign expenditures", and is recorded in 2018 as disagreeing with the Supreme Court decision that "lifts limits on corporations'' & unions'' spending in US elections" (OnTheIssues). Strictly limiting corporate and dark-money spending is this chair. ⚠ RE-CITED 2026-10-09: the row previously rested on a 2006 statement supporting public taxpayer funding of campaigns - nineteen years old, and pointing at a different rung than the one it was seated on. The chair does not move; only the evidence under it does.',
 ARRAY['https://ontheissues.org/governor/Tim_Walz_Government_Reform.htm']::text[],'Walz')
;

-- GUARD 1 — the table arrived whole and every target still carries a non-zero chair.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1916;
  IF n <> 7 THEN RAISE EXCEPTION 'migration 1916: expected 7 decisions, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1916 d
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id AND pa.value <> 0);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1916: % target(s) no longer carry a chair - re-measure', n; END IF;
END $$;

INSERT INTO inform.politician_answers (politician_id, topic_id, value, season_id, topic_revision_id)
SELECT d.politician_id, d.topic_id, d.new_value,
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, d.topic_revision_id
  FROM mig1916 d
ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
  SET value = EXCLUDED.value, updated_at = now();

-- Sources: the blanks carry the WITHDRAWN row's citations plus whatever this pass fetched, so the
-- record says what was checked. Bengs has none of his own because the superseding fact is the
-- ABSENCE of a current statement, which no URL can carry.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources, season_id, topic_revision_id)
SELECT d.politician_id, d.topic_id, d.reasoning,
       d.sources || COALESCE((SELECT pc0.sources FROM inform.politician_context pc0
                               WHERE pc0.politician_id = d.politician_id AND pc0.topic_id = d.topic_id
                                 AND coalesce(cardinality(pc0.sources),0) > 0
                               ORDER BY pc0.updated_at DESC NULLS LAST LIMIT 1), '{}'::text[]),
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, d.topic_revision_id
  FROM mig1916 d
ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources, updated_at = now();

-- GUARD 2 — verify the RESULT: 6 blanks, 1 chair preserved at 2, every row carrying a citation.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1916 d
    JOIN inform.politician_answers pa ON pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = d.new_value;
  IF n <> 7 THEN RAISE EXCEPTION 'migration 1916: expected 7 Season 2 rows at their decided value, found %', n; END IF;

  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 2'
    JOIN mig1916 d ON d.politician_id = pa.politician_id AND d.topic_id = pa.topic_id
   WHERE pa.value = 2 AND d.who = 'Walz';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1916: the Walz repair must keep its chair at 2; found % row(s)', n; END IF;

  SELECT count(*) INTO n FROM mig1916 d
    JOIN inform.politician_context pc ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources),0) = 0 AND d.who <> 'Bengs';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1916: % row(s) carry no citations', n; END IF;
END $$;
