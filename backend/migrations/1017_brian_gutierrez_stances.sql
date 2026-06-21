-- 1017_brian_gutierrez_stances.sql
-- Phase 152 Wave 4 (WCOV-01): evidence-only compass stances for Brian Gutierrez (West Covina D1, ext_id -201108).
-- AUDIT-ONLY raw SQL: does NOT register in schema_migrations (ledger stays 1011). Committed to EV-Accounts.
-- Thin Nov-2024 record -> 3 well-cited stances + honest blanks (NOT padded). pol_id 22fc2cdc-2f51-4d81-8814-4b54b2bc6582.
-- (Disambiguated from Brian Gutierrez the Chicago Fire soccer player — different person.)

BEGIN;
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('22fc2cdc-2f51-4d81-8814-4b54b2bc6582','e9ebefcd-c496-45e8-b816-a79f8442ba85',4),  -- public-safety-approach
('22fc2cdc-2f51-4d81-8814-4b54b2bc6582','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',3),  -- homelessness-response
('22fc2cdc-2f51-4d81-8814-4b54b2bc6582','eb3d1247-0de1-4b7f-baec-7259861efd53',4)   -- economic-development
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('22fc2cdc-2f51-4d81-8814-4b54b2bc6582','e9ebefcd-c496-45e8-b816-a79f8442ba85',$$In his 2024 campaign Gutierrez called to "improve public safety services by increasing the number of public safety officials out on patrol to help make our streets safe"; after taking office he supported the Jan 7 2025 police chief appointment and was recognized for securing $20,000 for a new police canine. This pro-staffing/resourcing posture matches chair 4.$$,ARRAY['https://www.ballotready.org/people/brian-gutierrez','https://westcovinaca.new.swagit.com/videos/325206']::text[]),
('22fc2cdc-2f51-4d81-8814-4b54b2bc6582','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',$$Gutierrez's campaign position: "I will demand the county finally provide Measure H funding that will allow us to help our homeless, especially those in need of mental health services. We will get those who want help the service they need, and those who don't want help will be asked to leave like the law allows." Pairing services/mental-health investment with enforcement of existing public-space rules matches chair 3.$$,ARRAY['https://www.ballotready.org/people/brian-gutierrez']::text[]),
('22fc2cdc-2f51-4d81-8814-4b54b2bc6582','eb3d1247-0de1-4b7f-baec-7259861efd53',$$Gutierrez campaigned to "create a streamlined process for new businesses to generate new revenue for our city" and to promote the downtown/Glendora Avenue and Plaza West Covina shopping areas. His emphasis on reducing barriers and recruiting development to grow the city's revenue base matches chair 4.$$,ARRAY['https://www.ballotready.org/people/brian-gutierrez']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
COMMIT;
-- AUDIT-ONLY: not registered in schema_migrations. Honest blanks on all other topics (thin Nov-2024 record).
