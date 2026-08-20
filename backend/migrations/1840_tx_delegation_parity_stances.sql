-- 1840_tx_delegation_parity_stances.sql
-- Texas US House delegation, parity pass: stances for members whose position could NOT be pinned
-- from a roll call.
--
-- ALREADY APPLIED to prod 2026-08-20; idempotent. Companion to 1839.
--
-- WHY THIS MIGRATION EXISTS
--
-- 1839 seated six members on a single roll call (H.R. 28) and noted the method is ASYMMETRIC: a Yea
-- on a single-subject bill can name a chair, a Nay only says "not that". That left five members with
-- nothing, all of whom had voted Nay. Fixing that by lowering the bar for them would have been worse
-- than the gap, so this pass went looking for evidence of the SAME standard: their own issue pages
-- and the bills they authored or sponsored.
--
-- WHAT THE SOURCE SURVEY FOUND (measured, five members)
--   Doggett and Crockett publish genuine first-person policy prose naming bills they authored.
--   Julie Johnson publishes structured policy prose on ONE topic (AI) and press feeds elsewhere.
--   Al Green and Marc Veasey publish press-release feeds filtered by a topic tag, not positions --
--     Green's "Social Security" page returns USPS and NAACP items from 2010 and 2020. The tag is
--     not a position statement and was not treated as one.
--
-- REFUSED, and these are the load-bearing decisions:
--   Veasey, Anti-Rigging Act of 2025 -> NOT a redistricting chair. It bars MID-DECADE redistricting
--     absent a court order, which constrains WHEN maps are redrawn, not WHO draws them. The
--     redistricting scale asks who draws. Compatible with four of the five chairs.
--   Julie Johnson, Reproductive Rights Are Human Rights Act of 2025 -> NOT an abortion chair. It
--     requires the State Department to resume reporting reproductive rights in its annual Human
--     Rights Reports: foreign-policy transparency, not a domestic legal framework.
--   Julie Johnson, AI -> HELD. She calls for a "smart, balanced regulatory framework" (which rules
--     out voluntary guidelines) and cosponsored a bill barring an AI-driven prior-authorisation
--     model in Medicare (which is banning a high-risk AI use in healthcare). But the disclosure and
--     liability clauses of one chair and the safety-testing clause of the next are both unevidenced,
--     so neither is fully met. Note this scale runs BACKWARDS -- 1 is least oversight.
--   Veasey and Doggett on healthcare -> HELD. Defending the ACA fits "everyone covered through a mix
--     of public and regulated private insurance" AND "help those who cannot afford it while keeping
--     private insurance", and nothing in the record separates them.
--   Doggett on immigration -> HELD. Sponsoring the American Dream and Promise Act is a legalisation
--     pathway; both candidate chairs turn on public-service access, which it does not address.
--
-- ON THE ONE ROW THAT LOOKS UNDER-STATED. Doggett is seated at voting-rights 2, not 1, although he
-- champions automatic and same-day registration. The most expansive chair also requires allowing
-- people to VOTE ONLINE, which he has not proposed -- his registration reforms concern getting on
-- the rolls, not casting ballots over the internet. Seating him at 1 would assert a position he does
-- not hold; chair 2's clauses are each evidenced by the For the People Act he sponsored. The
-- reasoning says so explicitly so the record is not silently narrowed.
--
-- Result: 5 rows across 2 members. Al Green, Marc Veasey and Julie Johnson remain at zero because
-- their published record does not name a chair, NOT because they were skipped.
--
-- Idempotency: ON CONFLICT DO NOTHING.

BEGIN;

WITH src(politician_id, topic_key, value, reasoning, sources) AS (VALUES
  ('ad8e300f-59f0-4cc6-a818-1986842353d1', 'abortion', 1,
   'Doggett sponsored the Women''s Health Protection Act, which would restore the right to access abortion and bar many state restrictions, and he also sponsored the Equal Access to Abortion Coverage in Health Insurance (EACH Woman) Act, which would extend abortion coverage to people on public health insurance, federal employees and federal health services. That second bill is what places him at this position rather than the next one along: public funding of abortion care is the feature that separates the most expansive option from simply keeping abortion legal and accessible. He describes himself as a member of the Congressional Reproductive Freedom Caucus with a 100 percent pro-choice voting record and has opposed anti-abortion riders on appropriations bills.',
   ARRAY['https://doggett.house.gov/issues/healthcare-0']),
  ('ad8e300f-59f0-4cc6-a818-1986842353d1', 'medicare/aid', 3,
   'Doggett''s Medicare record is a series of improvements to the existing programme rather than a change in its structure. He authored the Medicare Dental, Vision, and Hearing Benefit Act to add those benefits, the Close the Medigap Act to protect people with pre-existing conditions buying supplemental coverage, the Stop the Wait Act to phase out the waiting periods for disability enrollees, and the Assuring Medicare''s Promise Act to close a corporate tax loophole and shore up the Trust Fund. He pairs this with fraud and cost control measures including the enacted Medicare Identity Theft Prevention Act. On Medicaid he authored the COVER Now Act to let local governments extend Medicaid where the state has refused expansion. He has not proposed lowering the Medicare eligibility age or opening it to all ages, which is what the more expansive options on this scale require.',
   ARRAY['https://doggett.house.gov/issues/healthcare-0']),
  ('ad8e300f-59f0-4cc6-a818-1986842353d1', 'voting-rights', 2,
   'Doggett voted for and sponsored the For the People Act, whose access provisions include expanded early voting, no-excuse voting by mail, and automatic and same-day voter registration; he also opposed the House bill that would have barred using a driver''s licence for voter registration and effectively ended online and mail registration. Every element of this position is evidenced by that Act. The most expansive option on this scale additionally requires allowing people to vote online, which he has not proposed — his registration reforms concern how voters get on the rolls, not casting ballots over the internet.',
   ARRAY['https://doggett.house.gov/issues/voting-rights-0']),
  ('10d7e182-3200-41d1-b391-2b9abad273ca', 'voting-rights', 2,
   'Crockett states that federal action is needed to protect voter access and that she will push for legislation ranging from expanded vote-by-mail to online voter registration, which is an expansion of mail voting and registration rather than a move to automatic registration or internet voting. She has introduced voting legislation including the Democracy Restoration Act, which would end the permanent denial of voting rights to people with criminal convictions who have been released from incarceration, and legislation with Rep. Nikema Williams aimed at long lines and voter suppression.',
   ARRAY['https://crockett.house.gov/issues/voting-rights']),
  ('10d7e182-3200-41d1-b391-2b9abad273ca', 'housing', 3,
   'Crockett''s housing bills work by subsidising and incentivising affordable projects rather than by building public housing or capping rents. She introduced the Combatting the Housing Supply Shortage Act, which would increase the tax-exempt private activity bonds available in high-demand states to incentivise construction of new affordable housing, and the Rural Housing Voucher Enhancement Act, which improves the Rural Housing Voucher Program. Both are targeted subsidy and voucher tools directed at affordability; she has not proposed rent caps or inclusionary mandates, which the next option along would require.',
   ARRAY['https://crockett.house.gov/issues/economy-jobs-housing'])
),
resolved AS (
  SELECT s.politician_id::uuid AS pid, t.id AS tid, s.value::numeric AS val, s.reasoning, s.sources
  FROM src s JOIN inform.compass_topics t ON t.topic_key = s.topic_key AND t.is_live = true
),
ins_a AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT pid, tid, val FROM resolved
  ON CONFLICT (politician_id, topic_id) DO NOTHING
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pid, tid, reasoning, sources FROM resolved
ON CONFLICT (politician_id, topic_id) DO NOTHING;

DO $$
DECLARE
  v_dog uuid := 'ad8e300f-59f0-4cc6-a818-1986842353d1';
  v_cro uuid := '10d7e182-3200-41d1-b391-2b9abad273ca';
  v_rows int; v_ctx int;
BEGIN
  SELECT count(*) INTO v_rows FROM inform.politician_answers
   WHERE politician_id IN (v_dog, v_cro);
  IF v_rows <> 5 THEN
    RAISE EXCEPTION 'Expected 5 parity stances across Doggett and Crockett, found %', v_rows;
  END IF;

  SELECT count(*) INTO v_ctx
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
   WHERE a.politician_id IN (v_dog, v_cro)
     AND btrim(coalesce(c.reasoning,'')) <> '' AND coalesce(array_length(c.sources,1),0) > 0;
  IF v_ctx <> 5 THEN
    RAISE EXCEPTION 'Expected 5 contexts with reasoning AND sources, found %', v_ctx;
  END IF;

  RAISE NOTICE 'OK: 5 parity stances seated with sourced reasoning.';
END $$;

COMMIT;
