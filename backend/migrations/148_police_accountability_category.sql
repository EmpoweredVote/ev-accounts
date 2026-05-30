-- Assign "Police Accountability" to the "Public Safety and Law Enforcement" category.
-- This topic was live but uncategorized, causing it to be invisible in FullCalibration
-- and any other category-driven UI (e.g. Library topic browser).

INSERT INTO inform.compass_topic_categories (topic_id, category_id)
VALUES (
  '7bad33eb-e93e-4d94-8822-97212d49bde5',  -- Police Accountability
  '699a14d1-fc6d-48ac-b3dc-492f3f59ec6c'   -- Public Safety and Law Enforcement
)
ON CONFLICT DO NOTHING;
