-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H3 (15 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H3.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Walt Blackman (State House District 7) / public-safety-approach = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'public-safety-approach'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7', ct.id, $ctx$Sole prime sponsor of HB2602 (2R 2026), which appropriates $24.5 million from the state general fund for a 10% pay increase for all Department of Public Safety employees. This is a direct legislative act to increase police pay, matching the stance of increasing police staffing/pay to improve response times.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2602p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2356']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'public-safety-approach'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Walt Blackman (State House District 7) / homelessness = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7', ct.id, $ctx$Prime sponsor of HB2620 (2R 2026), which appropriates $300,000 annually for five years to the Department of Veterans' Services to grant to low-barrier emergency shelters (100+ beds, no pre-scheduled intake) serving homeless veterans. The bill is purely a shelter-capacity investment (no decriminalization language), narrower than the general population but shows a consistent pro-shelter-investment posture; scored conservatively given the veteran-specific scope.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2620p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2356']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Walt Blackman (State House District 7) / childcare = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7', ct.id, $ctx$Sole prime sponsor of HB2239 (2R 2026), which establishes a Child Care Grant Program and Child Care Infrastructure Fund at the Department of Economic Security, targeting underserved/rural, low- and moderate-income communities, nonstandard-hours care, infant/toddler care, and children with disabilities, with grants for facility/capacity expansion and provider business support. This is a significant provider-grant and subsidy-expansion program matching stance 2.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2239p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2356']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Walt Blackman (State House District 7) / housing = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7', ct.id, $ctx$Sole prime sponsor of HB2855 (2R 2026), 'Public Service Home Buyer Assistance Program,' establishing zero-down, low-interest mortgage loans and closing-cost assistance through the Arizona Finance Authority for law enforcement officers, firefighters, and teachers. This is targeted first-time/public-servant buyer assistance, matching stance 3's 'first-time buyer assistance' language exactly.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2855p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2356']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janeen Connolly (State House District 8) / same-sex-marriage = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd6f22ab7-5f0a-4d58-b53a-fd69bf4ad556', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd6f22ab7-5f0a-4d58-b53a-fd69bf4ad556', ct.id, $ctx$Co-sponsor of HCR2062 (2R 2026, prime sponsor Rep. Garcia), a concurrent resolution proposing to repeal Arizona's constitutional marriage ban (Article XXX, Sec. 1) and replace it with language stating marriage between two individuals shall not be prohibited based on sex, race, ethnicity, or national origin. This is a clear, individually-owned legislative action to remove the state's same-sex marriage ban, matching the most protective stance.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2062p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2357']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Garcia (State House District 8) / same-sex-marriage = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ea0e5f51-f963-45ef-a104-429af91e5f90', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ea0e5f51-f963-45ef-a104-429af91e5f90', ct.id, $ctx$Prime sponsor of HCR2062 (2R 2026), a concurrent resolution repealing Arizona's constitutional same-sex marriage ban and replacing it with language protecting marriage between two individuals regardless of sex. This direct legislative action matches the most protective stance on same-sex marriage.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2062p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2358']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Garcia (State House District 8) / campaign-finance = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ea0e5f51-f963-45ef-a104-429af91e5f90', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ea0e5f51-f963-45ef-a104-429af91e5f90', ct.id, $ctx$Prime sponsor of HB4046 (2R 2026, co-sponsored with Sen. Kuby), which amends Arizona's campaign finance reporting statute (16-926) to require that candidate committee reports itemize and specifically label contributions from registered lobbyists alongside occupation/employer information. This is a targeted disclosure-expansion bill matching the 'require full disclosure of all political donations' stance.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4046p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2358']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Garcia (State House District 8) / civil-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ea0e5f51-f963-45ef-a104-429af91e5f90', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ea0e5f51-f963-45ef-a104-429af91e5f90', ct.id, $ctx$Prime sponsor of HB2217 (2R 2026, prefiled Jan. 12, 2026), which amends Arizona's civil rights statutes (Title 41) governing employment, housing, and public accommodations to add 'sexual orientation, gender identity and gender expression' as protected classes alongside race, color, religion, sex, and national origin. This is a direct expansion of civil rights enforcement, matching the 'strengthen civil rights enforcement and address systemic discrimination' stance.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2217p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2358']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorena Austin (State House District 9) / same-sex-marriage = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62', ct.id, $ctx$Co-sponsor of HCR2062 (2R 2026, prime sponsor Rep. Garcia), the concurrent resolution to repeal Arizona's constitutional same-sex marriage ban. This individually-owned co-sponsorship of a narrow, specific resolution matches the most protective stance on same-sex marriage.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2062p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2343']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorena Austin (State House District 9) / childcare = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62', ct.id, $ctx$Sole prime sponsor of HB2626 (2R 2026), which establishes a Child Care Workforce Scholarship Program and appropriates $200 million to the Department of Economic Security to subsidize child care workers/educators below 85% of state median income, paid directly to contracted child care providers. This is a large-scale subsidy/provider-grant program matching stance 2.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2626p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2343']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorena Austin (State House District 9) / homelessness = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62', ct.id, $ctx$Sole prime sponsor of HB4123 (2R 2026), a 'Homeless Persons' Bill of Rights' establishing broad anti-discrimination protections in public spaces and services, plus a new provision (13-207) exempting homeless individuals from criminal liability for sitting, lying, or sleeping on public property specifically when no shelter space is available. The conditional decriminalization tied to shelter-bed availability matches the 'allowing enforcement only when adequate shelter beds are available' stance precisely.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4123p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2343']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorena Austin (State House District 9) / taxes = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62', ct.id, $ctx$Sole prime sponsor of HB2629 (2R 2026), which raises Arizona's corporate income tax minimum from $50 to $1,000 for corporations with 50 or more employees (requires a two-thirds legislative vote under the AZ Constitution's revenue-increase provision). This is a targeted, moderate tax increase on larger companies, matching the 'moderately raise taxes on...large companies' stance.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2629p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2343']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Blattman (State House District 9) / local-immigration = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '329dc518-7749-4671-b448-3ddaa396da9c', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '329dc518-7749-4671-b448-3ddaa396da9c', ct.id, $ctx$Sole prime sponsor of HB2657 (2R 2026), which bars Arizona law enforcement agencies (municipal, county, DPS) from entering, modifying, or renewing agreements to exercise federal civil immigration authority (287(g)) or to detain/house individuals in ICE custody, while explicitly preserving compliance with valid court-issued warrants and orders. This matches the 'comply only with court-ordered detainers' stance.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2657p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2295']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Blattman (State House District 9) / campaign-finance = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '329dc518-7749-4671-b448-3ddaa396da9c', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '329dc518-7749-4671-b448-3ddaa396da9c', ct.id, $ctx$Prime sponsor of HB4061 (2R 2026, co-sponsored with Rep. Villegas), which mandates that all candidates for statewide and legislative office in Arizona become participating candidates under the Citizens Clean Elections Act, limited to accepting and spending only public campaign funds. This is a direct mandate for full public financing of campaigns, matching the 'ban all private money in politics and publicly fund campaigns' stance.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4061p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2295']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Blattman (State House District 9) / voting-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '329dc518-7749-4671-b448-3ddaa396da9c', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '329dc518-7749-4671-b448-3ddaa396da9c', ct.id, $ctx$Sole prime sponsor of HB2654 (2R 2026), which amends multiple election statutes (16-245, 16-411, 16-461, 16-510, 16-542, 16-544) to rename Arizona's 'active early voting list' back to a 'permanent early voting list,' removing the periodic reconfirmation/purge requirement enacted in 2021. This restores broader, ongoing access to mail voting, matching the 'expand early voting periods and make mail-in voting available to all voters' stance.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2654p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2295']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
