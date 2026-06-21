-- 1015_letty_lopez_viado_stances.sql
-- Phase 152 Wave 4 (WCOV-01): evidence-only compass stances for Letty Lopez-Viado (West Covina D2, Mayor, ext_id 687361).
-- AUDIT-ONLY raw SQL: does NOT register in schema_migrations (ledger stays 1011). Committed to EV-Accounts.
-- CHAIRS model, 100% citation, honest blanks. pol_id 2872d7a4-612b-4d9d-9531-699e3c344002. 4 evidence-backed stances.

BEGIN;
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('2872d7a4-612b-4d9d-9531-699e3c344002','e9ebefcd-c496-45e8-b816-a79f8442ba85',4),  -- public-safety-approach
('2872d7a4-612b-4d9d-9531-699e3c344002','4938766b-b45a-46e3-93bd-b8b30651271a',4),  -- homelessness (criminalization)
('2872d7a4-612b-4d9d-9531-699e3c344002','eb3d1247-0de1-4b7f-baec-7259861efd53',4),  -- economic-development
('2872d7a4-612b-4d9d-9531-699e3c344002','f7e5678d-dadd-4556-a2fc-446e24642ceb',4)   -- taxes
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('2872d7a4-612b-4d9d-9531-699e3c344002','e9ebefcd-c496-45e8-b816-a79f8442ba85',$$Lopez-Viado drafted and voted for West Covina's June 2021 letter (passed 4-1) demanding LA County DA Gascón rescind his progressive directives, objecting to declined misdemeanor prosecutions and elimination of sentencing enhancements; her official bio lists "supporting and strengthening our public safety" as a priority. This pro-enforcement, deterrence-focused posture matches chair 4.$$,ARRAY['https://www.laadda.com/2021/06/27/san-gabriel-valley-tribune-west-covina-sends-letter-to-d-a-criticizing-changes-hes-made/','https://www.westcovina.gov/directory.aspx?eid=37']::text[]),
('2872d7a4-612b-4d9d-9531-699e3c344002','4938766b-b45a-46e3-93bd-b8b30651271a',$$At an April 2023 council meeting Lopez-Viado asked staff to consider legislation to monitor unhoused people and to explore rules restricting people from returning to homeless encampments. This enforcement-oriented, encampment-restricting approach (rather than protecting public sleeping) aligns with chair 4's graduated prohibition of encampments.$$,ARRAY['https://sac.media/2023/04/23/west-covina-to-move-forward-on-requiring-permits-for-street-parking/']::text[]),
('2872d7a4-612b-4d9d-9531-699e3c344002','eb3d1247-0de1-4b7f-baec-7259861efd53',$$Lopez-Viado's official bio states her priority is "building a business friendly community that supports our local business as well as attracting new businesses to generate new tax revenue," and the city touts a "pro-business government." This emphasis on actively recruiting businesses to grow the tax base matches chair 4.$$,ARRAY['https://www.westcovina.gov/directory.aspx?eid=37','https://asianjournal.com/usa/southerncalifornia/letty-lopez-viado-ascends-to-west-covina-ca-mayorship-becoming-first-filipina-mexican-american-in-top-role/']::text[]),
('2872d7a4-612b-4d9d-9531-699e3c344002','f7e5678d-dadd-4556-a2fc-446e24642ceb',$$Lopez-Viado's stated priority is "using common sense to balance the budget by controlling spending," and during the pandemic she opposed strict enforcement against businesses ("We're not going to be too hard on our businesses"). Her fiscal posture emphasizes spending restraint and a low burden on businesses rather than raising taxes, best matching chair 4. [Softest mapping of her four — controlling-spending leans 4 but is between chairs 3 and 4.]$$,ARRAY['https://www.westcovina.gov/directory.aspx?eid=37','https://asianjournal.com/usa/southerncalifornia/letty-lopez-viado-ascends-to-west-covina-ca-mayorship-becoming-first-filipina-mexican-american-in-top-role/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
COMMIT;
-- AUDIT-ONLY: not registered in schema_migrations.
