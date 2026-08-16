-- 1770_wa_taxes_cohort_6346.sql
-- 26 rows on `taxes`, all at chair 2. Cohort: every sponsor of ESSB 6346, the millionaires' tax
-- (Chapter 238, Laws of 2026) — 26 Democratic senators, 8 of whom held no compass row at all.
--
-- ── why chair 2 and not chair 1 ───────────────────────────────────────────────────────────────────
-- Chair 1 is "significantly raise taxes on wealthy people and large companies to fund MORE public
-- services"; chair 2 is the same raise "to fund EXISTING services". The ratified discriminator is the
-- DESTINATION of the revenue, never the significantly/moderately adverb — bills do not characterise
-- their own magnitude (set by migration 1759, Mosqueda = 1 on "entirely new investment"; applied in
-- migration 1762, Fitzgibbon = 2).
-- ESSB 6346 states its own destination twice, and both statements are chair 2:
--   · §1(6) "the intent of this act is to MAINTAIN AND PRESERVE essential governmental services";
--   · §202 deposits the revenue in the general fund "to fund the sales and use tax relief in sections
--     903 through 908 ..., the working families' tax credit ..., and the business and occupation tax
--     relief in sections 909 through 911 ..., and to make public investments in K-12 education,
--     health care, human services, and higher education" — the four general fund purposes the act's
--     own §1(1)-(5) describes the state as ALREADY funding.
-- The House companion HB 2724 carried the identical §1(6) and seated Fitzgibbon at chair 2, so this
-- cohort is consistent with the row already in the corpus rather than a fresh reading.
--
-- 🔑 NEW PRECEDENT — AN INTENT SECTION'S ASPIRATIONS ARE NOT A DESTINATION. Read against HB 2724, the
-- enacted Senate act ADDS language that sounds like chair 1, and every added item is intent-only with
-- NO operative section anywhere in its 110 pages:
--   · §1(2) breakfast and lunch "for all children served without charge each school day" — the act
--     creates no meal programme (the standalone free-meals bill, SB 5352, died);
--   · §1(12) a "city and county fiscal health account" the legislature "intends to create" — not
--     created here;
--   · §1(13)(e) "increase state funding for K-12 education" — no appropriation in this act.
-- A session reading only section 1 would have seated 26 senators at chair 1 on programmes that do not
-- exist. Parts IX, X and XI of the act are titled TAX RELIEF and conforming amendments; the only new
-- dedicated money is §202(2)'s five percent to the pre-existing fair start for kids account, from
-- 2029. Same family as [read the enacted text, never the title]: here the trap is one level deeper —
-- the enacted INTENT text, contradicted by the enacted OPERATIVE text.
--
-- ── the other three chairs are refuted, not merely unproven ───────────────────────────────────────
--   · chair 3 ("keep the current tax system mostly as-is with small adjustments to close unfair
--     loopholes") — the act adds an entire new Title 82A RCW and a tax Washington has never levied;
--   · chairs 4 and 5 (cut taxes and scale back services) — it raises taxes on the top 0.5% and cuts
--     no service. The tax relief it funds is directed at consumers and small business, not paired
--     with any reduction in services.
--
-- ── per-member screen: 20 flagged, 12 competing instruments read, NOBODY MOVED ────────────────────
-- The screen (`wa_screen_cohort.py "SB 6346" tax`, keyword set added for this cohort) flagged 20 of
-- the 26 as holding their own primary-sponsored tax bill. All 12 that could plausibly reach a
-- different chair were read in full:
--   · Pedersen SB 5798 (property tax reform) — lifts the 1% levy growth limit because it "has
--     severely inhibited the ability ... to provide critical services": chair 2, reinforcing.
--   · Frame SB 5797 (wealth tax on intangibles) — "raising new progressive revenue for our public
--     schools" to meet EXISTING basic education obligations: chair 2.
--   · Saldaña SB 5796 (payroll excise on large employers) — §1(5) "the intent of this act is to
--     maintain and preserve essential services": chair 2 verbatim. SB 6093 backfills the medicaid and
--     SNAP cuts of federal H.R. 1 — preservation again.
--   · Stanford SB 5314 (capital gains) — self-described as "not estimated to affect state or local
--     tax collections"; Robinson SB 5777 (payment processors) — an explicitly prospective technical
--     fix; Lovelett SB 5811 (zero-emission credit windfalls) — neither reaches the ladder.
--   · Orwall SB 5762 (988 crisis line tax) and Slatter SB 5775 (local option sales tax) raise money
--     from EVERYONE, not from "wealthy people and large companies", so neither chair 1 nor chair 2
--     describes them.
--   · Kauffman SB 6347 undoes the 2025 estate tax increase — a cut, but with no service-reduction
--     clause it reaches no chair, exactly as Ed Orcutt's eight tax-cut bills reached none (mig 1764).
--     Recorded because it sits against her chair-2 row, and the reader should know it is there.
--   · Salomon SB 5794 eliminates obsolete tax preferences — chair 3's "close unfair loopholes" in
--     isolation, but chair 3 is refuted for him by 6346 itself, which does not keep the system as-is.
--
-- ⚠ TWO NEAR-MISSES, recorded so a later reader can overturn them with the evidence in hand. Both
-- members primary-sponsored a tax on large companies dedicated to a NEW programme — chair 1's
-- description:
--   · C. Wilson SB 5799 — a 0.4% B&O surtax on social media platforms creating the youth behavioral
--     health account;
--   · Saldaña SB 5638 — an excise tax on excess hospital executive compensation to "increase
--     Washingtonians' access to health care ... programmes that advance health equity".
-- They stay at chair 2 because each also authored a larger instrument stating the opposite
-- destination in the act's own words — Wilson's enacted SB 5813 dedicates a more progressive capital
-- gains and estate tax to "fund ONGOING SUPPORT of public K-12 education, early learning and child
-- care, and higher education", and Saldaña's SB 5796 says "maintain and preserve". Where a member's
-- own record states both destinations, the ladder cannot discriminate for that member and the
-- instrument they signed governs. This is NOT the forbidden "least extreme option" tiebreaker: chair
-- 2 is positively evidenced for all 26 by §1(6) of the act each of them sponsored.
--
-- Mechanics: rows generated from the sponsorship cache, never hand-typed; identity is the member ID
-- (name-only linkage — Emily Alvarado sponsored from the House and sits in the Senate); apostrophes
-- escaped in the RAISE EXCEPTION literals (T'wina Nobles failed a whole migration once).
BEGIN;

CREATE TEMP TABLE tx_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='14332488-3986-4e86-abc2-666b7a3f2dd5' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Annette Cleveland already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='14332488-3986-4e86-abc2-666b7a3f2dd5' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Annette Cleveland already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='219f7fc7-d02b-46a0-acad-dfc09814ed11' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Bob Hasegawa already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='219f7fc7-d02b-46a0-acad-dfc09814ed11' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Bob Hasegawa already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f6c042e3-b785-4bf2-b385-65a34ff616e8' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claire Wilson already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f6c042e3-b785-4bf2-b385-65a34ff616e8' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claire Wilson already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4042de49-5bea-413c-aecd-9abbe742a9a2' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claudia Kauffman already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4042de49-5bea-413c-aecd-9abbe742a9a2' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claudia Kauffman already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='78230dff-4e33-4d33-8c46-71f00db01858' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Derek Stanford already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='78230dff-4e33-4d33-8c46-71f00db01858' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Derek Stanford already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5a36591c-66c5-4cb1-b99d-d7fc7fa93b25' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Emily Alvarado already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='5a36591c-66c5-4cb1-b99d-d7fc7fa93b25' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Emily Alvarado already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='3ac881c7-2d11-42c1-9bc0-23f54770a64b' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamie Pedersen already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='3ac881c7-2d11-42c1-9bc0-23f54770a64b' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamie Pedersen already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d1e47ce6-4390-47e0-937e-3c710e81abbb' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Javier Valdez already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d1e47ce6-4390-47e0-937e-3c710e81abbb' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Javier Valdez already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='15808557-b30b-44cf-bad2-e627fa547e1a' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jesse Salomon already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='15808557-b30b-44cf-bad2-e627fa547e1a' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jesse Salomon already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1e6d175b-1af0-444c-b373-e5d0a279d240' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jessica Bateman already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1e6d175b-1af0-444c-b373-e5d0a279d240' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jessica Bateman already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='47ac1908-3715-4599-82f6-606aaf2d9fe6' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Lovick already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='47ac1908-3715-4599-82f6-606aaf2d9fe6' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Lovick already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7ac92b63-d489-45d5-a85f-c0deac9d8508' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: June Robinson already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7ac92b63-d489-45d5-a85f-c0deac9d8508' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: June Robinson already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1ff1e922-601b-45f3-a43d-2ef69220f54b' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Wellman already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1ff1e922-601b-45f3-a43d-2ef69220f54b' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Wellman already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='207ff383-f26e-462b-a554-72472b52712a' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Lovelett already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='207ff383-f26e-462b-a554-72472b52712a' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Lovelett already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0097aee3-e409-44bc-ba20-121108c11ec7' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Manka Dhingra already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0097aee3-e409-44bc-ba20-121108c11ec7' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Manka Dhingra already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c3fccc57-8278-43c8-8e54-dc3c78e50bc9' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marcus Riccelli already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c3fccc57-8278-43c8-8e54-dc3c78e50bc9' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marcus Riccelli already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Chapman already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Chapman already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4991ee01-0a35-454f-bdf6-bb2f34cf1c30' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Noel Frame already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4991ee01-0a35-454f-bdf6-bb2f34cf1c30' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Noel Frame already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4218b4c2-d642-431e-a279-5aff5100379f' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rebecca Saldaña already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4218b4c2-d642-431e-a279-5aff5100379f' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rebecca Saldaña already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7902547a-e33b-4fff-8a77-5d4e76163f47' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Shewmake already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7902547a-e33b-4fff-8a77-5d4e76163f47' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Shewmake already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='054dd953-bc6b-44de-8173-00efab5a9c04' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Conway already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='054dd953-bc6b-44de-8173-00efab5a9c04' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Conway already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='436194e1-479e-4066-8d99-f325fd6bb880' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: T''wina Nobles already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='436194e1-479e-4066-8d99-f325fd6bb880' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: T''wina Nobles already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7535e225-d3d0-40ca-ba9c-3890563c40a0' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tina Orwall already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7535e225-d3d0-40ca-ba9c-3890563c40a0' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tina Orwall already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2147a010-bd4e-445c-840a-8d5ad69573ca' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Vandana Slatter already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='2147a010-bd4e-445c-840a-8d5ad69573ca' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Vandana Slatter already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2ffd9e47-b0f1-428f-9164-01025dd34310' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Victoria Hunt already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='2ffd9e47-b0f1-428f-9164-01025dd34310' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Victoria Hunt already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c09a622c-ec49-40e9-87db-ead331f5ab9e' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Yasmin Trudeau already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c09a622c-ec49-40e9-87db-ead331f5ab9e' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Yasmin Trudeau already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND value=2;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: taxes chair 2 not defined exactly once (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND topic_key='taxes' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: taxes topic is not live/active'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('14332488-3986-4e86-abc2-666b7a3f2dd5','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('219f7fc7-d02b-46a0-acad-dfc09814ed11','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('f6c042e3-b785-4bf2-b385-65a34ff616e8','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('4042de49-5bea-413c-aecd-9abbe742a9a2','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('78230dff-4e33-4d33-8c46-71f00db01858','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('3ac881c7-2d11-42c1-9bc0-23f54770a64b','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Prime sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('d1e47ce6-4390-47e0-937e-3c710e81abbb','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('15808557-b30b-44cf-bad2-e627fa547e1a','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('1e6d175b-1af0-444c-b373-e5d0a279d240','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('47ac1908-3715-4599-82f6-606aaf2d9fe6','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('7ac92b63-d489-45d5-a85f-c0deac9d8508','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('1ff1e922-601b-45f3-a43d-2ef69220f54b','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('207ff383-f26e-462b-a554-72472b52712a','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('0097aee3-e409-44bc-ba20-121108c11ec7','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('c3fccc57-8278-43c8-8e54-dc3c78e50bc9','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('4991ee01-0a35-454f-bdf6-bb2f34cf1c30','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('4218b4c2-d642-431e-a279-5aff5100379f','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('7902547a-e33b-4fff-8a77-5d4e76163f47','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('054dd953-bc6b-44de-8173-00efab5a9c04','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('436194e1-479e-4066-8d99-f325fd6bb880','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('7535e225-d3d0-40ca-ba9c-3890563c40a0','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('2147a010-bd4e-445c-840a-8d5ad69573ca','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('2ffd9e47-b0f1-428f-9164-01025dd34310','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']),
('c09a622c-ec49-40e9-87db-ead331f5ab9e','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('14332488-3986-4e86-abc2-666b7a3f2dd5','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('219f7fc7-d02b-46a0-acad-dfc09814ed11','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('f6c042e3-b785-4bf2-b385-65a34ff616e8','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('4042de49-5bea-413c-aecd-9abbe742a9a2','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('78230dff-4e33-4d33-8c46-71f00db01858','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('3ac881c7-2d11-42c1-9bc0-23f54770a64b','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('d1e47ce6-4390-47e0-937e-3c710e81abbb','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('15808557-b30b-44cf-bad2-e627fa547e1a','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('1e6d175b-1af0-444c-b373-e5d0a279d240','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('47ac1908-3715-4599-82f6-606aaf2d9fe6','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('7ac92b63-d489-45d5-a85f-c0deac9d8508','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('1ff1e922-601b-45f3-a43d-2ef69220f54b','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('207ff383-f26e-462b-a554-72472b52712a','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('0097aee3-e409-44bc-ba20-121108c11ec7','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('c3fccc57-8278-43c8-8e54-dc3c78e50bc9','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('4991ee01-0a35-454f-bdf6-bb2f34cf1c30','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('4218b4c2-d642-431e-a279-5aff5100379f','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('7902547a-e33b-4fff-8a77-5d4e76163f47','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('054dd953-bc6b-44de-8173-00efab5a9c04','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('436194e1-479e-4066-8d99-f325fd6bb880','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('7535e225-d3d0-40ca-ba9c-3890563c40a0','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('2147a010-bd4e-445c-840a-8d5ad69573ca','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('2ffd9e47-b0f1-428f-9164-01025dd34310','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('c09a622c-ec49-40e9-87db-ead331f5ab9e','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM tx_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 26 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +26', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 26 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +26', s.ctx_before, ctx_after; END IF;
END $$;

DO $$
DECLARE bad int; c2 int; primes int;
BEGIN
  -- content, not merely that an INSERT ran: the chair value, the clause the chair was read from,
  -- and the source actually fetched.
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND a.politician_id IN ('14332488-3986-4e86-abc2-666b7a3f2dd5','219f7fc7-d02b-46a0-acad-dfc09814ed11','f6c042e3-b785-4bf2-b385-65a34ff616e8','4042de49-5bea-413c-aecd-9abbe742a9a2','78230dff-4e33-4d33-8c46-71f00db01858','5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','3ac881c7-2d11-42c1-9bc0-23f54770a64b','d1e47ce6-4390-47e0-937e-3c710e81abbb','15808557-b30b-44cf-bad2-e627fa547e1a','1e6d175b-1af0-444c-b373-e5d0a279d240','47ac1908-3715-4599-82f6-606aaf2d9fe6','7ac92b63-d489-45d5-a85f-c0deac9d8508','1ff1e922-601b-45f3-a43d-2ef69220f54b','207ff383-f26e-462b-a554-72472b52712a','0097aee3-e409-44bc-ba20-121108c11ec7','c3fccc57-8278-43c8-8e54-dc3c78e50bc9','cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','4218b4c2-d642-431e-a279-5aff5100379f','7902547a-e33b-4fff-8a77-5d4e76163f47','054dd953-bc6b-44de-8173-00efab5a9c04','436194e1-479e-4066-8d99-f325fd6bb880','7535e225-d3d0-40ca-ba9c-3890563c40a0','2147a010-bd4e-445c-840a-8d5ad69573ca','2ffd9e47-b0f1-428f-9164-01025dd34310','c09a622c-ec49-40e9-87db-ead331f5ab9e')
     AND (a.value <> 2
          OR c.reasoning !~ 'maintain and preserve essential governmental services'
          OR c.reasoning !~ 'Chapter 238, Laws of 2026'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % row(s) wrong chair, missing the destination clause, or missing the session law', bad; END IF;

  SELECT count(*) INTO c2 FROM inform.politician_answers
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND value=2 AND politician_id IN ('14332488-3986-4e86-abc2-666b7a3f2dd5','219f7fc7-d02b-46a0-acad-dfc09814ed11','f6c042e3-b785-4bf2-b385-65a34ff616e8','4042de49-5bea-413c-aecd-9abbe742a9a2','78230dff-4e33-4d33-8c46-71f00db01858','5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','3ac881c7-2d11-42c1-9bc0-23f54770a64b','d1e47ce6-4390-47e0-937e-3c710e81abbb','15808557-b30b-44cf-bad2-e627fa547e1a','1e6d175b-1af0-444c-b373-e5d0a279d240','47ac1908-3715-4599-82f6-606aaf2d9fe6','7ac92b63-d489-45d5-a85f-c0deac9d8508','1ff1e922-601b-45f3-a43d-2ef69220f54b','207ff383-f26e-462b-a554-72472b52712a','0097aee3-e409-44bc-ba20-121108c11ec7','c3fccc57-8278-43c8-8e54-dc3c78e50bc9','cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','4218b4c2-d642-431e-a279-5aff5100379f','7902547a-e33b-4fff-8a77-5d4e76163f47','054dd953-bc6b-44de-8173-00efab5a9c04','436194e1-479e-4066-8d99-f325fd6bb880','7535e225-d3d0-40ca-ba9c-3890563c40a0','2147a010-bd4e-445c-840a-8d5ad69573ca','2ffd9e47-b0f1-428f-9164-01025dd34310','c09a622c-ec49-40e9-87db-ead331f5ab9e');
  IF c2 <> 26 THEN RAISE EXCEPTION 'guard 2: chair-2 count is %, expected 26', c2; END IF;

  -- exactly one prime sponsor; a bug flattening the sponsor types would show up here
  SELECT count(*) INTO primes FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND politician_id IN ('14332488-3986-4e86-abc2-666b7a3f2dd5','219f7fc7-d02b-46a0-acad-dfc09814ed11','f6c042e3-b785-4bf2-b385-65a34ff616e8','4042de49-5bea-413c-aecd-9abbe742a9a2','78230dff-4e33-4d33-8c46-71f00db01858','5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','3ac881c7-2d11-42c1-9bc0-23f54770a64b','d1e47ce6-4390-47e0-937e-3c710e81abbb','15808557-b30b-44cf-bad2-e627fa547e1a','1e6d175b-1af0-444c-b373-e5d0a279d240','47ac1908-3715-4599-82f6-606aaf2d9fe6','7ac92b63-d489-45d5-a85f-c0deac9d8508','1ff1e922-601b-45f3-a43d-2ef69220f54b','207ff383-f26e-462b-a554-72472b52712a','0097aee3-e409-44bc-ba20-121108c11ec7','c3fccc57-8278-43c8-8e54-dc3c78e50bc9','cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','4218b4c2-d642-431e-a279-5aff5100379f','7902547a-e33b-4fff-8a77-5d4e76163f47','054dd953-bc6b-44de-8173-00efab5a9c04','436194e1-479e-4066-8d99-f325fd6bb880','7535e225-d3d0-40ca-ba9c-3890563c40a0','2147a010-bd4e-445c-840a-8d5ad69573ca','2ffd9e47-b0f1-428f-9164-01025dd34310','c09a622c-ec49-40e9-87db-ead331f5ab9e') AND reasoning LIKE 'Prime sponsor of %';
  IF primes <> 1 THEN RAISE EXCEPTION 'guard 2: % prime-sponsor row(s), expected 1', primes; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'taxes: 26 senators at chair 2 from ESSB 6346; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
