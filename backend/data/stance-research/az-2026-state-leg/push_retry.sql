-- ============================================================================
-- AZ state-leg RETRY wave 2026-07-13 - 38 stance rows / 12 legislators
-- Zero-row legislators re-researched via azleg bill-PDF pipeline (3 Sonnet agents).
-- Orchestrator review: DROP Lupe Diaz abortion (off-axis funding bill HB2154),
--   DROP Carter fossil-fuels (HB4025 study-committee only); ADD Epstein school-vouchers=2
--   (SB1264 co-sponsor parity w/ Sears). 5 bills PDF-cover-verified by orchestrator.
-- politician_id from _ROSTER.csv (AZ-scoped). topic_id via inform.compass_topics.
-- ============================================================================
BEGIN;

-- Aaron Márquez / abortion=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, $ctx$Campaign platform ("Protecting Abortion Rights") commits to repealing "archaic and barbaric" state abortion laws including the fifteen-week abortion ban, framing this as protecting patients and providers in a "post-Roe America." Committing to repeal a 15-week ban implies support for legal access at least through the second trimester, without an explicit call for public funding or unrestricted access at all stages, matching the chair keeping abortion legal and accessible through the second trimester.$ctx$, ARRAY['https://www.aaronmarquez.com/issues']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Aaron Márquez / campaign-finance=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, $ctx$Prime sponsor of HB2598 (2R, 2026) and its identical predecessor HB2622 (1R, 2025), both amending A.R.S. 16-937 to double late-filing penalties for campaign finance committees ($10 to $20 for the first 15 days, $25 to $50 thereafter) and add temporary/permanent suspension of a committee's operating authority for repeated non-filing. The bill strengthens compliance with existing disclosure filing requirements rather than touching contribution limits, matching the chair calling for full disclosure of political donations.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB2598P.pdf','https://www.azleg.gov/legtext/57leg/1R/bills/HB2622P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2355']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Aaron Márquez / childcare=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, $ctx$Prime sponsor of HB4024 (2R, 2026), which amends A.R.S. 36-884 to exempt family child care programs certified by a branch of the U.S. Department of Defense or the U.S. Coast Guard from state child-care licensing requirements. This is a narrow but clear regulatory exemption aimed at increasing the supply of available child care for military families by removing a state licensing requirement, matching the chair on reducing regulations on providers to increase supply. Evidence is limited to this one carve-out, not a broad deregulation platform.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB4024P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2355']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Aaron Márquez / housing=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, $ctx$Sole prime sponsor of HB2938 (1R, 2025), which creates a state "Home Buyer Assistance Program" within the Arizona Finance Authority to provide low-interest, zero-down-payment mortgage loans and closing-cost assistance to eligible buyers (law enforcement officers, firefighters, and certificated teachers with 5+ years of service) who do not currently own other real estate. This is a targeted, means-limited buyer-assistance subsidy program, matching the chair offering targeted subsidies and first-time buyer assistance rather than broad public housing or market deregulation.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/1R/bills/HB2938P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=129&legislator=2355']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Aaron Márquez / immigration=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, $ctx$Prime sponsor of HB2572 (57th Leg., 2R, 2026) and its identical predecessor HB2812 (1R, 2025), both titled "in-state student status; nonimmigrant aliens," amending A.R.S. 15-1803 so that "persons without lawful immigration status are eligible for in-state tuition." Reintroducing the identical measure in both sessions of his term shows sustained individual effort to extend a public service (in-state tuition) to undocumented residents, matching the stance that keeps legal immigration open and lets most residents use public services regardless of status.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB2572P.pdf','https://www.azleg.gov/legtext/57leg/1R/bills/HB2812P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2355']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Aaron Márquez / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, $ctx$Campaign platform ("Improving Our Schools") explicitly opposes SB1165, the 2022 law restricting transgender student-athletes to teams matching sex assigned at birth, calling it "the recent attack on transgender student-athletes" and pledging to "fight to remove and prevent measures that discriminate against marginalized students." This unqualified opposition to any sex-based competition restriction matches the chair allowing transgender athletes to compete on teams matching gender identity without restrictions.$ctx$, ARRAY['https://www.aaronmarquez.com/issues']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Aaron Márquez / voting-rights=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0df9cd85-3923-48bd-86c2-b7d4b31d510d', ct.id, $ctx$Campaign platform (aaronmarquez.com/issues, "Protecting Our Democracy") states support for automatic voter registration, free state IDs, same-day registration, expanded early voting through Election Day, and counting ballots postmarked by Election Day, plus making Election Day a holiday. This bundle, led by automatic registration, is the most expansive package on the scale, matching the chair calling for automatic registration of all eligible citizens.$ctx$, ARRAY['https://www.aaronmarquez.com/issues']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Alma Hernandez / childcare=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e4460c64-fa27-4e05-96e8-cc005a478444', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e4460c64-fa27-4e05-96e8-cc005a478444', ct.id, $ctx$Prime-sponsored HB4099 (2026), which creates the Arizona Working Parents Child Care Program funded by a dedicated share of state lottery revenue and requires the department to 'allow all eligible parents to participate in the program without paying fees and regardless of income,' paying participating providers directly for services to infants through kindergarten-age children. This is an explicitly publicly funded, fee-free, income-blind child care program, matching stance 1's universal childcare model.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4099p.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2312']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Alma Hernandez / housing=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e4460c64-fa27-4e05-96e8-cc005a478444', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e4460c64-fa27-4e05-96e8-cc005a478444', ct.id, $ctx$Prime-sponsored HB2682 (2026), creating a $5,000,000 rental assistance program administered by the Department of Economic Security for tenant families with a child under 18 who have lived in the rental home at least 12 months and are facing 'an unexpected and temporary financial emergency' (capped at two months or $5,000 per household per year), with anti-eviction protection for the months covered. This is a targeted, income/circumstance-verified subsidy rather than direct public housing construction or broad rent regulation, matching stance 3's 'targeted help' approach.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2682p.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2312']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Alma Hernandez / jail-capacity=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e4460c64-fa27-4e05-96e8-cc005a478444', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e4460c64-fa27-4e05-96e8-cc005a478444', ct.id, $ctx$Co-led (with fellow HD-20/21/24 Hernandez members and others) HB4083 (2026), which amends Arizona bail law to add 'whether the accused has the financial ability to pay bail' as a required factor in release decisions and mandates that electronic monitoring be provided 'at no charge to the person' for defendants released on qualifying felony charges. These are modest bail-reform provisions aimed at reducing wealth-based pretrial detention rather than expanding jail capacity, aligning with stance 2's emphasis on bail reform to reduce the incarcerated population.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4083p.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2312']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Catherine Miranda / deportation=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f1b19116-3c6f-4c44-9faf-bc32db5fc5d2', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f1b19116-3c6f-4c44-9faf-bc32db5fc5d2', ct.id, $ctx$Prime-sponsored SB1031 (2026), 'immigration; law enforcement; repeal,' which repeals Arizona's Title 11 Chapter 7 Article 8 border-security enforcement structure, repeals the state crime for failing to carry alien registration documents (13-1509), repeals the state crimes for harboring/transporting/concealing unauthorized immigrants (13-2928, 13-2929), strips peace officers of warrantless-arrest authority based on removability from the U.S. (13-3883), and repeals the border-security/immigration-enforcement funding subaccount (41-1724). This comprehensive rollback of Arizona's SB1070-era state immigration-enforcement infrastructure is the strongest available signal of a stance favoring protection of undocumented residents from state-facilitated removal, matching stance 1.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1031p.pdf','https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2392']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Catherine Miranda / local-immigration=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f1b19116-3c6f-4c44-9faf-bc32db5fc5d2', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f1b19116-3c6f-4c44-9faf-bc32db5fc5d2', ct.id, $ctx$Prime-sponsored SB1708 (2026), which bars any city, town, county, or state-owned property (including parking lots, garages, and vacant lots) from being used, occupied, leased, or staged for civil immigration enforcement absent a valid judicial warrant specific to that property, requires posted signage at every public entrance stating this restriction, and bars officers from questioning, detaining, or arresting anyone on such property without a judicial warrant applicable to that person. This is a sweeping, sanctuary-style restriction on any local or state cooperation with civil immigration enforcement, closely matching stance 1.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1708p.pdf','https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2392']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Catherine Miranda / school-vouchers=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f1b19116-3c6f-4c44-9faf-bc32db5fc5d2', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f1b19116-3c6f-4c44-9faf-bc32db5fc5d2', ct.id, $ctx$Prime-sponsored SB1264 (2026), which requires a mandatory legislative program review and Auditor General performance audit of the Arizona Empowerment Scholarship Accounts (ESA) voucher program at least 17 months before its scheduled July 2034 termination date, assessing whether there remains a documented 'need for the program' before the legislature may vote to continue it. She also prime-sponsored companion bills SB1305 ('ESAs; personnel; ADE; reporting requirements') and SB1306 ('ESAs; expenditures; enrollment; limitations') per the same session's bill list, indicating a sustained push to add accountability, reporting, and limits to the voucher program rather than expand it further. This pattern of subjecting ESAs to review, reporting, and limitation (without abolishing them outright) is the closest match to stance 2.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1264p.pdf','https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2392']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Denise "Mitzi" Epstein / childcare=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'feecd8fc-b007-450a-8779-8e6f68e80dd6', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'feecd8fc-b007-450a-8779-8e6f68e80dd6', ct.id, $ctx$Prime-sponsored SB1727 (2026) amending Arizona's existing income-based child care assistance program, which phases out eligibility between 165% of the federal poverty level and 85% of state median income and imposes copayments and work/training requirements; her amendment loosens one participation rule (allowing at least half-time, rather than full-time, school enrollment to waive the work requirement). This maintains and modestly adjusts an existing targeted, means-tested subsidy system rather than pursuing universal or significantly expanded childcare, matching stance 3.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1727p.pdf','https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2377']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Denise "Mitzi" Epstein / school-vouchers=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'feecd8fc-b007-450a-8779-8e6f68e80dd6', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'feecd8fc-b007-450a-8779-8e6f68e80dd6', ct.id, $ctx$Co-sponsored SB1264 (2026), which imposes a mandatory legislative program review, an Auditor General performance audit, and a hard July 1, 2034 termination date on Arizona's universal Empowerment Scholarship Account (ESA) voucher program (prime sponsor Miranda; co-sponsors include Epstein and Sears). Adding an accountability/sunset mechanism to the universal voucher program rather than expanding it aligns with stance 2. Scored on co-sponsorship of a substantive anchor bill, consistent with the AZ wave's established co-sponsorship standard and mirroring the identical SB1264-based row credited to co-sponsor Sears.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/SB1264P.pdf','https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2377']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Denise "Mitzi" Epstein / taxes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'feecd8fc-b007-450a-8779-8e6f68e80dd6', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'feecd8fc-b007-450a-8779-8e6f68e80dd6', ct.id, $ctx$Prime-sponsored SB1800 (2026), titled the 'Billionaires Should Pay for the Infrastructure They Use Act,' which imposes an additional 2.6-percentage-point individual income tax rate on federal adjusted gross income over $1,000,000 (raising the effective top marginal rate from 2.5% to 5.1%, the rate in effect in 1998), dedicating the new revenue to a K-12 school-building infrastructure fund. This is a direct, substantial tax increase targeted at the highest earners to fund public services, matching stance 1.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1800p.pdf','https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2377']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Justin Olson / climate-change=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2af8f7d8-79ac-4668-9771-fdfff27ecc6c', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2af8f7d8-79ac-4668-9771-fdfff27ecc6c', ct.id, $ctx$Prime sponsor of HB2912 (2026), requiring electric utilities to file triennial integrated resource plans evaluated via a cost/reliability-based 'Ratepayer Impact Measure,' with bill text stating the required analysis is explicitly 'not...meant to satisfy any carbon or emissions reduction goal.' Favoring a cost-and-reliability-driven utility planning process over emissions-reduction mandates matches stance 4's 'let market forces drive any transition to cleaner energy sources' rather than a stance mandating faster fossil-fuel phase-out.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB2912P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2359']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Justin Olson / housing=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2af8f7d8-79ac-4668-9771-fdfff27ecc6c', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2af8f7d8-79ac-4668-9771-fdfff27ecc6c', ct.id, $ctx$Prime sponsor of HB4066 (2026), amending A.R.S. Section 9-463.05 to bar municipalities from charging development impact fees exceeding the proportionate cost of services a new development actually uses, restricting local governments' ability to charge builders for broader infrastructure costs. This regulatory rollback lowering the cost of new construction for private developers matches stance 4's 'cut regulations...so private developers can build more housing.'$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB4066P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2359']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Justin Olson / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2af8f7d8-79ac-4668-9771-fdfff27ecc6c', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2af8f7d8-79ac-4668-9771-fdfff27ecc6c', ct.id, $ctx$Prime sponsor of HB4030 (2026), a four-year moratorium (FY2026-27 through FY2029-30) barring Arizona municipalities and counties from raising fees, transaction privilege tax rates, or utility rates above 2025-2026 levels, freezing local government revenue-raising broadly (not targeted at wealthy individuals or corporations) and constraining public-service budgets as costs rise. This structural, economy-wide tax/fee freeze matches stance 4's 'cut taxes for everyone and scale back public services to match' rather than stance 3's minor loophole-closing adjustments.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB4030P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2359']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Kiana Sears / abortion=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, $ctx$Co-sponsored a coordinated 2026 (2R) bloc of bills repealing Arizona's remaining state-level abortion restrictions: SB1219 repeals A.R.S. 1-219 (a statutory "unborn children; rights; privileges" provision), SB1220 repeals the notarized-parental-consent requirement for a minor's abortion, and SB1395 repeals Arizona's abortion reporting-requirements statute (Title 36, Ch.20, Art.2). This pattern of deregulating remaining state abortion restrictions, consistent with Arizona's 2024 Prop 139 constitutional protection of abortion through fetal viability, aligns most closely with stance 2 (legal and accessible through the second trimester, with rare exceptions after).$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/SB1219P.pdf','https://www.azleg.gov/legtext/57leg/2R/bills/SB1220P.pdf','https://www.azleg.gov/legtext/57leg/2R/bills/SB1395P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Kiana Sears / data-centers=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, $ctx$Co-sponsored SB1380 (2026), which requires "large load customers" -- expressly defined to include data centers -- to pay their own increased energy costs (fuel, generation, transmission) and bars public power entities and the Corporation Commission from passing those costs on to other ratepayers. Also co-sponsored SB1467 (2026), which among other tax-code changes repeals a cross-reference to a since-repealed data-center tax-relief certification (former A.R.S. 41-1519), removing a data-center tax break. Together these match stance 2 (data centers fund their own power; cost-shifting to residential ratepayers barred).$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/SB1380P.pdf','https://www.azleg.gov/legtext/57leg/2R/bills/SB1467P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Kiana Sears / healthcare=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, $ctx$Prime-sponsored SB1797 (2026), her only solo prime-sponsored health bill, which prohibits "price gouging" on essential off-patent/generic drugs, empowers the Attorney General to investigate and penalize manufacturers over steep price increases, and ties enforcement to protecting the state's AHCCCS medical assistance program. This reflects support for government regulation of a private health-related market to control costs and protect a public program, the closest fit to stance 2's regulated-private-market approach, though the bill addresses drug pricing specifically rather than insurance coverage directly.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/SB1797P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Kiana Sears / local-immigration=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, $ctx$Co-sponsored two 2026 companion bills sharply limiting state and local cooperation with federal civil immigration enforcement: SB1660, the "Immigration Safe Zones Act," directs the Attorney General to adopt policies limiting state-agency assistance with immigration enforcement at schools, hospitals, libraries and courts, and to strip citizenship/immigration-status questions from state applications; SB1708 bars city, county and state property (including parking lots) from being used for civil immigration enforcement absent a judicial warrant and bars warrantless questioning/detention on public property. Together these functionally extend sanctuary-type restrictions on ICE cooperation to state and local government, the closest match to stance 1 (refuse cooperation, protect information from federal agencies).$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/SB1660P.pdf','https://www.azleg.gov/legtext/57leg/2R/bills/SB1708P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Kiana Sears / school-vouchers=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, $ctx$Co-sponsored SB1264 (2026), which imposes a mandatory legislative program review, a performance audit by the Auditor General, and a hard termination date (July 1, 2034) on Arizona's universal Empowerment Scholarship Account (ESA) voucher program. Adding an accountability/sunset mechanism to the state's universal voucher program, rather than expanding it further, reflects a position favoring oversight and eventual reconsideration of vouchers over unconditional expansion, aligning with stance 2.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/SB1264P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Kiana Sears / voting-rights=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fef8eb85-8360-418d-8239-ccf3a823608b', ct.id, $ctx$Co-sponsored SB1343 (2026), the "Arizona State Voting Rights Act," which guarantees the right to vote and to representation, mandates minority-language voting materials, prohibits voter suppression, and empowers courts to order remedies including additional voting hours/days, more polling locations, expanded means of voting, and expanded voter-registration opportunities. This broad pro-access, anti-suppression framework is the closest fit to stance 2 (expanding voting access), though the bill's specific mechanism (a private/AG civil right of action against suppression) differs somewhat from the stance text's early-voting/mail-voting framing.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/SB1343P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Mae Peshlakai / fossil-fuels=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fe4cbf96-b145-48d7-9fcf-120e6b75c290', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='fossil-fuels'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fe4cbf96-b145-48d7-9fcf-120e6b75c290', ct.id, $ctx$Prime sponsor of HCM2014 (2026), a bipartisan memorial (16 cosponsors) urging Congress to 'continue to maintain the national monuments located in Arizona.' The memorial argues outdoor-recreation/tourism revenue outweighs extraction benefits and specifically criticizes proposed uranium mining near monument lands, while citing polling that 87% of Arizonans support creating new protected lands. This favors halting expanded extraction/permitting on public lands over allowing new drilling/mining, aligning with stance 2 rather than a full extraction ban since existing permitted uses are acknowledged, not targeted for elimination.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HCM2014P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2332']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='fossil-fuels'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Mae Peshlakai / jail-capacity=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fe4cbf96-b145-48d7-9fcf-120e6b75c290', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fe4cbf96-b145-48d7-9fcf-120e6b75c290', ct.id, $ctx$Prime sponsor of HB2595 (2026), which appropriates $45,000,000 to Coconino County, part of which converts the county's existing juvenile detention center into a detoxification/sobriety/crisis-recovery treatment facility. Redirecting existing incarceration capacity into community-based addiction and mental-health treatment matches stance 1's language on shrinking the jail system by redirecting funding into treatment and recovery programs.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB2595P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2332']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Mae Peshlakai / public-safety-approach=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fe4cbf96-b145-48d7-9fcf-120e6b75c290', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='public-safety-approach'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fe4cbf96-b145-48d7-9fcf-120e6b75c290', ct.id, $ctx$Prime sponsor of HB4091 (2026), which creates a permanent $10,000,000/year 'tribal government rural law enforcement enhancement fund' to help tribal governments in rural counties hire and retain law enforcement officers and purchase communication/IT equipment. This individually-authored appropriation directly expands police staffing and equipment capacity, matching stance 4's emphasis on increasing police staffing/equipment rather than redirecting funds to other services. (Note: this compass question is framed at the city level; Peshlakai's documented action is a state appropriation funding tribal rural law enforcement, the closest individual evidence available for a state legislator.)$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB4091P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2332']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='public-safety-approach'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Myron Tsosie / economic-development=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '47a75797-e525-4dd9-ab04-66dd4d667760', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='economic-development'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '47a75797-e525-4dd9-ab04-66dd4d667760', ct.id, $ctx$Prime sponsor of HB2886 (2026), directing the Arizona Commerce Authority to adopt rules creating a technical-assistance and state-procurement-preference program prioritizing Native-owned cooperatives, artisans, and rural small enterprises, rather than large corporate subsidies. This targeted small-business support matches stance 2's focus on small-business/entrepreneur programs while avoiding large-employer tax abatements. (Note: this compass question is framed at the city level; Tsosie's documented action is a state-level economic-development program targeted at tribal/rural small businesses, the closest individual evidence available.)$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB2886P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2341']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='economic-development'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Myron Tsosie / housing=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '47a75797-e525-4dd9-ab04-66dd4d667760', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '47a75797-e525-4dd9-ab04-66dd4d667760', ct.id, $ctx$Prime sponsor of HB2891 (2026), appropriating $15,000,000 from the state housing trust fund for tribal housing infrastructure (water/sewer systems), construction-trade apprenticeships, and partnerships with tribal housing authorities. This direct public appropriation to fund new housing infrastructure matches stance 2's 'publicly fund new housing' language.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB2891P.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2341']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Pamela Carter / housing=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '23675559-e2dd-4e26-abed-2f87954dc70e', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '23675559-e2dd-4e26-abed-2f87954dc70e', ct.id, $ctx$As sole prime sponsor of HB2667 (57th Legislature, 2nd Regular Session 2026), Carter added new eligibility rules to Arizona's state-run first-time homebuyer/downpayment assistance programs: a two-year state residency requirement for recipients, a two-year primary-residence occupancy requirement, and a bar on out-of-state investors participating. Rather than eliminating or expanding the state's homebuyer assistance programs, she preserved the targeted-assistance model while tightening it against investor/absentee abuse, matching 'offer targeted help like subsidies for affordable projects, first-time buyer assistance...' (chair 3).$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB2667P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Pamela Carter / medicare/aid=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '23675559-e2dd-4e26-abed-2f87954dc70e', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '23675559-e2dd-4e26-abed-2f87954dc70e', ct.id, $ctx$Carter is sole prime sponsor of HB2980 (57th Legislature, 2R 2026), which creates a new AHCCCS (Arizona Medicaid) home-and-community-based-services benefit for adults with serious mental illness, capped at 500 enrollees, with income-based financial eligibility (up to 300% of the federal SSI benefit rate) and enhanced provider reimbursement tied to accountability requirements (eviction-prevention protocols, annual outcome reporting). The bill incrementally expands a specific Medicaid service line while imposing enrollment caps, income tests, and cost/utilization reporting, consistent with 'improve current programs while controlling costs' (chair 3).$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB2980P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Ralph Heap / climate-change=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '92b03e09-8251-4eb8-a50e-966d52a592e1', ct.id, 5.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '92b03e09-8251-4eb8-a50e-966d52a592e1', ct.id, $ctx$Prime-sponsored a 2026 bloc of bills that erects new, renewable-energy-specific hurdles: HB2338 requires full board attendance, a majority vote, AND a separate approving vote from every supervisory district touching the site (unanimous if a district's member recuses) before a county with under 500,000 population may approve any use permit or zoning change for a wind or solar project; HB2341 adds a 'speculativeness'/known-offtakers test to the certificate-of-environmental-compatibility factors used for power-plant and transmission-line siting; and HB2975 suspends the State Land Department's use of 'solar scores' in state-trust-land decisions, replacing them with new mining- and housing-focused resource maps developed only with industry stakeholder input. Together, this bloc actively works to slow and deprioritize wind/solar siting and land use rather than merely deregulating, which is the closest match to stance 5's rejection of climate-oriented energy policy in favor of other priorities.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2338p.pdf','https://www.azleg.gov/legtext/57leg/2R/bills/hb2341p.pdf','https://www.azleg.gov/legtext/57leg/2R/bills/hb2975p.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Ralph Heap / data-centers=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '92b03e09-8251-4eb8-a50e-966d52a592e1', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '92b03e09-8251-4eb8-a50e-966d52a592e1', ct.id, $ctx$Prime-sponsored HB4097 (2026), the 'Bring Your Own Power Bill Act,' which creates a self-supply registration pathway letting 'large customers' (10-25+ MW, i.e., data centers and similar campuses) build dedicated generation and private lines to serve their own load without obtaining a full Certificate of Convenience and Necessity from the Corporation Commission. The bill explicitly caps self-supply to the large customer and its affiliated/colocation load only and bars resale to the public, keeping this load off the incumbent utility's rate base rather than requiring ratepayers to fund infrastructure for it. This closely matches stance 2's requirement that data centers fund their own dedicated generation rather than shifting infrastructure costs to residential customers.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4097p.pdf','https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2360']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Selina Bliss / immigration=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b8c33072-6368-4465-8352-14e9fabddfbe', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b8c33072-6368-4465-8352-14e9fabddfbe', ct.id, $ctx$As prime sponsor of HB2728 (the 2026 Department of Economic Security continuation bill), Bliss introduced a March 3, 2026 floor amendment that would require hospitals accepting Medicaid to ask patients about their citizenship/immigration status on intake forms, tighten SNAP eligibility verification, and expand work requirements for benefits recipients (reviving provisions Gov. Hobbs had previously vetoed). This documents a stance of limiting public benefits/services access based on legal status, matching the 'limit public services to people with legal status' language of stance 4; there is no evidence in this record of her position on legal immigration levels specifically, so the score reflects only the public-services axis.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB2728P.pdf','https://azmirror.com/2026/03/18/arizona-republicans-stuff-vetoed-proposals-into-a-must-pass-agency-extension-bill/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Stephanie Simacek / healthcare=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '84bb6849-a68d-42e0-999d-dd0456b9d0b4', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '84bb6849-a68d-42e0-999d-dd0456b9d0b4', ct.id, $ctx$Simacek prime-sponsored a bloc of health-insurance regulation bills across both the 2025 and 2026 sessions: HB2782 (2025, reintroduced nearly verbatim as HB2581 in 2026) creates a Health Care Claims Consumer Assistance Program, declares wrongful claim denials unlawful, and imposes civil penalties and double damages on insurers who wrongfully deny or underpay valid claims; HB2292 (2025), the "Donna Hicks Act," mandates that private insurers, HMOs, disability insurers, and AHCCCS (Arizona's Medicaid program) cover hereditary-cancer genetic counseling and testing with no deductible, coinsurance, or other cost-sharing; and HB2294 (2025) closes a facility-fee licensure loophole for hospital-affiliated outpatient clinics. Together these bills regulate and strengthen coverage within the existing mixed private-insurance/public-program system rather than proposing single-payer or a fully private market, matching stance 2.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/1R/bills/HB2782P.pdf','https://www.azleg.gov/legtext/57leg/1R/bills/HB2292P.pdf','https://www.azleg.gov/legtext/57leg/1R/bills/HB2294P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Stephanie Simacek / housing=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '84bb6849-a68d-42e0-999d-dd0456b9d0b4', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '84bb6849-a68d-42e0-999d-dd0456b9d0b4', ct.id, $ctx$Simacek prime-sponsored HB2817 (2025), responding to investors forcibly terminating condominium associations and buying out owners below market value. The bill requires supermajority owner votes, independent appraisals with an arbitration backstop, and relocation/closing-cost payments to owner-occupants, and adds legislative-intent language declaring 'a vital public interest in maintaining these forms of private property ownership as affordable and essential housing.' This is a regulatory intervention to preserve existing affordable housing stock and prevent investor-driven displacement rather than a subsidy/incentive or deregulatory approach, making stance 2's interventionist posture the closest fit — though the bill does not itself involve rent caps or new-development mandates, so this is an imperfect match flagged for review.$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/1R/bills/HB2817P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Stephanie Simacek / school-vouchers=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '84bb6849-a68d-42e0-999d-dd0456b9d0b4', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '84bb6849-a68d-42e0-999d-dd0456b9d0b4', ct.id, $ctx$Simacek prime-sponsored HB2884 (2025) and its 2026 successor HB2580, both adding accountability requirements to Arizona's Empowerment Scholarship Account (ESA) voucher program. HB2884 requires identity-verified fingerprint clearance cards for any person contracted to provide ESA-funded tutoring services; HB2580 extends fingerprinting, a minimum age, and a clean disciplinary record to ESA-funded micro-school and tutoring staff who have unsupervised contact with students, as a new condition of ESA tuition/fee eligibility. Neither bill seeks to eliminate or restrict ESA eligibility, nor to expand it further — both add safety/accountability guardrails to the existing voucher program, which is the closest match to stance 3's accountability-requirement language (note: Arizona's ESA is a universal, not means-tested, program, so the income-based clause of stance 3 does not literally apply; the rating rests on the accountability-requirement pattern in her own bills).$ctx$, ARRAY['https://www.azleg.gov/legtext/57leg/1R/bills/HB2884P.pdf','https://www.azleg.gov/legtext/57leg/2R/bills/HB2580P.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;

