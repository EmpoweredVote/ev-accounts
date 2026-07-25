-- =============================================================================
-- Migration 1405: web_form_url batch — 11 Collin-milestone cities with a
-- confirmed, submittable city-wide contact form
-- (Phase 220 Plan 02 — Contact Data Backfill, Wave 2)
--
-- Seeds essentials.politicians.web_form_url with the ONE sourced, city-wide
-- contact-form URL for EVERY currently-seated official of each of the 11
-- cities below (D-01: one form URL applies to every official of a city).
-- Idempotent: only writes WHERE web_form_url IS NULL (D-07); re-applying this
-- migration is net-zero. Scoped by governments.geo_id -> chambers ->
-- offices.politician_id -> politicians.id, so an official can only receive a
-- value if they currently hold a seat in one of the 11 governments below —
-- structurally impossible to leak outside the 11 geo_ids.
--
-- SEEDED (verbatim URL transcribed from 220-RESEARCH.md's Per-City Sourcing
-- Table; each confirmed this session to embed an actual <form> element with a
-- submit action, not a mailto/PDF/311-app/plain listing page — Pitfall 1):
--   Farmersville  (4825488) -> farmersvilletx.com/contact-us            (Drupal Webform)
--   Lavon         (4841800) -> lavontx.gov/contact-us/                  (general contact form)
--   Longview      (4843888) -> longviewtexas.gov FormCenter "City Council" form
--   Murphy        (4850100) -> murphytx.org/1967/Contact-Council        (CognitoForms embed)
--   Princeton     (4859576) -> princetontx.gov FormCenter "Tell Us" form
--   Prosper       (4859696) -> prospertx.gov FormCenter "Public Comment Request Form"
--   Van Alstyne   (4874924) -> cityofvanalstyne.us/contactus            (mwjsForm widget)
--   Blue Ridge    (4808872) -> blueridgecity.com/contact-us             (dept-dropdown form)
--   Melissa       (4847496) -> cityofmelissa.com FormCenter "Contact Us" category
--   Nevada        (4850760) -> cityofnevadatx.org/contact_us/index.php  ("General Contact Form")
--   Fairview      (4825224) -> fairviewtexas.org/contact-us/            (Ninja Forms embed)
--
-- EXCLUDED (deliberately NOT seeded here — documented honest-blank/deferred,
-- not an oversight; see 220-RESEARCH.md Per-City table + Open Questions for
-- the full citation trail on each):
--   - A city where the only submittable form found is addressed to a single
--     named officeholder (mayor-only), not a general council-wide form, so it
--     does not meet D-01's "one form for every official" bar.
--   - A city whose only online-submission mechanism is a 311-style
--     service-request app (potholes/code violations) rather than a
--     contact-your-council form — judged not a D-01 qualifying form.
--   - A city whose best-candidate form is addressed to a city-manager/staff
--     office rather than the council, and whose officials already carry
--     qualifying personal/seat-alias emails independent of any form (no gap
--     to close).
--   - Several cities whose "Contact Us"-named pages resolve, on raw-HTML
--     inspection, to a generic mailto link, a downloadable PDF (print-and-mail),
--     or a department-specific form only — none of which is a submittable
--     city-wide council-contact form (Pitfall 1).
--   - Three cities whose official sites blocked this milestone's automated
--     fetch entirely (redirect loop / JS-rendered platform / WAF 403) — their
--     form URL (if any) is unconfirmed and deferred to a later migration, not
--     guessed here.
-- =============================================================================

BEGIN;

UPDATE essentials.politicians p
SET web_form_url = v.url
FROM (VALUES
  ('4825488', 'https://www.farmersvilletx.com/contact-us'),
  ('4841800', 'https://lavontx.gov/contact-us/'),
  ('4843888', 'https://longviewtexas.gov/FormCenter/Contact-Us-5/City-Council-44'),
  ('4850100', 'https://www.murphytx.org/1967/Contact-Council'),
  ('4859576', 'https://princetontx.gov/FormCenter/Contact-Us-4/Contact-Us-46'),
  ('4859696', 'https://www.prospertx.gov/FormCenter/Town-Secretary-14/Public-Comment-Request-Form-83'),
  ('4874924', 'https://cityofvanalstyne.us/contactus'),
  ('4808872', 'https://blueridgecity.com/contact-us'),
  ('4847496', 'https://www.cityofmelissa.com/FormCenter/Contact-Us-12/Contact-Us-60'),
  ('4850760', 'https://cityofnevadatx.org/contact_us/index.php'),
  ('4825224', 'https://fairviewtexas.org/contact-us/')
) AS v(geo_id, url)
JOIN essentials.governments g ON g.geo_id = v.geo_id
JOIN essentials.chambers ch ON ch.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = ch.id
WHERE p.id = o.politician_id
  AND p.is_active = true
  AND p.web_form_url IS NULL;

COMMIT;
