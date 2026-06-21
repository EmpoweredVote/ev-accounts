-- 1016_rosario_diaz_stances.sql
-- Phase 152 Wave 4 (WCOV-01): evidence-only compass stances for Rosario Diaz (West Covina D3, ext_id -201107).
-- AUDIT-ONLY raw SQL: does NOT register in schema_migrations (ledger stays 1011). Committed to EV-Accounts.
-- Thin record -> 1 well-cited stance + many honest blanks (NOT padded). pol_id f5bf4ec4-7d1b-460e-b4e2-539826c59596.

BEGIN;
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('f5bf4ec4-7d1b-460e-b4e2-539826c59596','e9ebefcd-c496-45e8-b816-a79f8442ba85',4)  -- public-safety-approach
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('f5bf4ec4-7d1b-460e-b4e2-539826c59596','e9ebefcd-c496-45e8-b816-a79f8442ba85',$$Diaz's official council bio states she "maintains unwavering support for our men and women in public safety" and is committed to West Covina's independent (non-contracted) Police and Fire Departments; she was endorsed by the West Covina Police Officers and Fire Fighters Associations, and on Jan 7 2025 voted 5-0 to confirm the new police chief, praising the choice. This posture of strengthening and well-resourcing an in-house police force matches chair 4.$$,ARRAY['https://www.westcovina.gov/directory.aspx?eid=39','https://www.publicceo.com/2025/01/west-covina-appoints-antonio-cortina-as-new-chief-of-police/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
COMMIT;
-- AUDIT-ONLY: not registered in schema_migrations. Honest blanks on all other topics (thin Nov-2024 record).
