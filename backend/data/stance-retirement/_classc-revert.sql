BEGIN;
-- revert Mary Beth Carozza / Civil Rights and Social Justice (chair 4.0)
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[], reasoning = 'Carozza has opposed expansions of civil rights categories and affirmative action measures, consistent with conservative Republican positions on civil rights in Maryland.'
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;
-- revert Sara Love / Same-Sex Marriage (chair 5.0)
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02','https://ballotpedia.org/Sara_Love']::text[], reasoning = 'Love supports same-sex marriage and LGBTQ equality. As a Montgomery County Democrat, she voted for LGBTQ anti-discrimination legislation and consistently supports marriage equality.'
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
COMMIT;
