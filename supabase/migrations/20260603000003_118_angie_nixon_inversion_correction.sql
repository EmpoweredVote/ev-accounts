-- Correction migration for Angie Nixon (politician_id: 0ac89151-2b8d-4430-b9bd-3a80bef3413b)
-- FL State Senate candidate; formerly FL State Representative (2020–present), Jacksonville
-- Source date: 2026-06-02 (research from batch-A CSV)
-- Corrections: 9 topics; original data had 91% uniform value=4 lock (confirmed inversion)
-- Corrected values are mostly 1-2, reflecting progressive FL Democratic primary candidate
-- Topics corrected: abortion, civil-rights, immigration, taxes, voting-rights, school-vouchers,
--   redistricting, healthcare, campaign-finance

BEGIN;

-- abortion: value corrected to 1 (explicit bodily autonomy/reproductive rights framing)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ac89151-2b8d-4430-b9bd-3a80bef3413b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Nixon''s campaign priorities page states: ''Freedom is not a slogan. It is control over your body, your future, and your ability to live without fear.'' This is canonical reproductive rights/bodily autonomy framing from progressive Democrats. As a Florida Democratic State Representative since 2020, Nixon has consistently aligned with the most expansive reproductive rights position in contrast to Governor DeSantis''s abortion restrictions (6-week ban, 15-week ban) that she has opposed. Her campaign runs explicitly as an opposition to the Florida conservative establishment on reproductive rights. This fits value 1 (ensure abortion is legal, accessible, and publicly funded at all stages of pregnancy).',
  ARRAY['https://angienixon.com/priorities/', 'https://angienixon.com/meet-angie/', 'https://en.wikipedia.org/wiki/Angie_Nixon']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- civil-rights: value corrected to 1 (co-founded Melanin Market, sued FL over detention access)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ac89151-2b8d-4430-b9bd-3a80bef3413b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Nixon co-founded the Melanin Market for small Black business owners, opened Cafe Resistance (a space for ''promoting black history and culture through literature and storytelling in opposition to state repression of historical accounts of African-American resistance''), served as SEIU labor organizer, introduced a resolution calling for Gaza ceasefire (voted 104-2 against), and sued the state after being denied access to the Everglades immigration detention facility. Her campaign explicitly calls out ''public systems should serve the public — not private profit.'' She has a documented track record of racial equity advocacy and structural discrimination opposition, fitting value 1 (mandate racial equity requirements in all institutions and provide reparations) in the FL progressive Democratic context.',
  ARRAY['https://angienixon.com/priorities/', 'https://angienixon.com/meet-angie/', 'https://en.wikipedia.org/wiki/Angie_Nixon']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- immigration: value corrected to 1 (sued FL over detention facility access, anti-ICE legislation)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ac89151-2b8d-4430-b9bd-3a80bef3413b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Nixon sued the State of Florida after being denied access to the Everglades immigration detention facility (known as ''Alligator Alcatraz''). She introduced legislation requiring ICE and law enforcement agents to unmask and identify themselves. Her campaign website has a section titled ''Standing Up For Our Immigrant Neighbors.'' As a progressive Democrat representing a heavily Democratic Jacksonville district who fought against Florida''s immigration enforcement practices, her position fits value 1 (stop deportations entirely and protect undocumented residents from removal / make it easier for immigrants to come legally and use public services).',
  ARRAY['https://angienixon.com/state-rep-angie-nixon-launchescampaign-for-u-s-senate/', 'https://angienixon.com/meet-angie/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- taxes: value corrected to 1 (anti-billionaire/anti-corporate, labor-powered campaign)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ac89151-2b8d-4430-b9bd-3a80bef3413b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Nixon''s campaign platform states she is running ''because corrupt billionaires and greedy corporations rig the system'' and calls for ''a government that creates opportunity'' that is ''not funded by corporate PACs, not directed by lobbyists and DC consultants.'' She frames the campaign as labor-powered, explicitly anti-corporate-capture. As an SEIU/labor movement Democrat running on an economic justice platform, her position aligns with value 1 (significantly raise taxes on wealthy people and large companies to fund more public services) — she explicitly endorses an economy where corporations and billionaires no longer dictate policy to the disadvantage of working families.',
  ARRAY['https://angienixon.com/priorities/', 'https://angienixon.com/meet-angie/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- voting-rights: value corrected to 1 (led sit-ins, registered voters, blocked redistricting)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ac89151-2b8d-4430-b9bd-3a80bef3413b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Nixon led high-profile floor protests against Governor DeSantis''s 2022 congressional redistricting scheme, attempting to stage a sit-in to prevent the vote. In 2026, she used a megaphone to disrupt a redistricting vote and was reprimanded by the FL House. She also serves as Executive Director of Florida for All, a statewide coalition that ''registered tens of thousands of new voters.'' Her documented pattern — actively registering voters, opposing restrictive redistricting, blocking anti-voter legislation — aligns with value 1 (automatically register all eligible citizens to vote and allow online voting) at the most expansive end.',
  ARRAY['https://en.wikipedia.org/wiki/Angie_Nixon', 'https://angienixon.com/meet-angie/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- school-vouchers: value corrected to 1 (SEIU-backed, anti-corporate-capture of public systems)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ac89151-2b8d-4430-b9bd-3a80bef3413b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Nixon''s campaign focuses on ''expanding childcare for thousands of families'' and ''opening the door to the people.'' As a labor union organizer (SEIU) and former public school ally, her campaign platform calls for public investment in education. Her opposition to corporate capture extends to public school funding — SEIU has historically strongly opposed public school voucher programs that redirect taxpayer money to private institutions. Nixon''s campaign explicitly calls out opposition to powerful interests controlling public systems. This fits value 1 (fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions).',
  ARRAY['https://angienixon.com/priorities/', 'https://angienixon.com/meet-angie/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- redistricting: value corrected to 1 (led sit-in protests against legislative redistricting)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ac89151-2b8d-4430-b9bd-3a80bef3413b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  'Nixon led a sit-in protest in 2022 against DeSantis''s congressional redistricting scheme, attempting to block the vote. In May 2026, she used a megaphone in a loud protest to disrupt a redistricting vote and was reprimanded. In her Wikipedia entry, her protests against redistricting are described as fighting for ''democracy.'' Her documented actions — physical protests against legislative redistricting carried out by politicians — align with value 1 (independent citizens'' commissions with no elected officials involved at any level), reflecting opposition to legislative control of district mapping.',
  ARRAY['https://en.wikipedia.org/wiki/Angie_Nixon', 'https://angienixon.com/meet-angie/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- healthcare: value corrected to 2 (affordability/access mix, ACA-aligned, not single-payer)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ac89151-2b8d-4430-b9bd-3a80bef3413b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Nixon''s launch announcement states Floridians are ''crushed by an affordability crisis'' where ''the cost of everything is exploding: groceries, healthcare, and childcare.'' Her campaign pledges to fight for a ''government that creates opportunity, respects our dignity, and puts all working families and seniors first'' on healthcare. As a SEIU/labor Democrat, she supports universal affordable coverage but her specific platform focuses on access and affordability through a mix of expanded programs and regulated private options rather than a pure Medicare for All framing — consistent with value 2 (make sure everyone has affordable coverage through a mix of public programs and regulated private insurance).',
  ARRAY['https://angienixon.com/state-rep-angie-nixon-launchescampaign-for-u-s-senate/', 'https://angienixon.com/priorities/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- campaign-finance: value corrected to 1 (explicitly no corporate PACs, no lobbyists, campaign answers only to The People)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ac89151-2b8d-4430-b9bd-3a80bef3413b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Nixon''s campaign explicitly states it is ''not funded by corporate PACs, not directed by lobbyists and DC consultants, and not beholden to AIPAC or any group that expects to shape U.S. policy without accountability to the people.'' She states ''This campaign answers to one group only: The People.'' She is explicitly running as a grassroots campaign in opposition to the influence of money in politics. This aligns with value 1 (ban all private money in politics and publicly fund campaigns) — her campaign''s foundational premise is removing corporate and special interest money from political influence.',
  ARRAY['https://angienixon.com/priorities/', 'https://angienixon.com/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
