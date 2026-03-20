-- Phase 34: RLS + grants for essentials schema (36 tables)
-- All tables are public-read. No INSERT/UPDATE/DELETE policies — all writes via service role (pool.query()).

BEGIN;

-- ============================================================
-- Section 1: Enable RLS on every table
-- ============================================================
ALTER TABLE essentials.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.building_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.chambers ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.committees ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.degrees ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.election_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.endorsements ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.endorser_organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.experiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.geofence_boundaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.government_bodies ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.governments ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.identifiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.judge_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.judicial_disciplinary_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.judicial_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.judicial_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.legislative_bill_cosponsors ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.legislative_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.legislative_committee_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.legislative_committees ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.legislative_leadership_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.legislative_politician_id_map ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.legislative_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.legislative_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.politician_committees ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.politician_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.politician_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.politician_stances ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.politicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.position_descriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.zip_politicians ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Section 2: Public-read policies
-- ============================================================
CREATE POLICY "addresses: public read"
  ON essentials.addresses FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "building_photos: public read"
  ON essentials.building_photos FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "chambers: public read"
  ON essentials.chambers FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "committees: public read"
  ON essentials.committees FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "degrees: public read"
  ON essentials.degrees FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "districts: public read"
  ON essentials.districts FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "election_records: public read"
  ON essentials.election_records FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "endorsements: public read"
  ON essentials.endorsements FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "endorser_organizations: public read"
  ON essentials.endorser_organizations FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "experiences: public read"
  ON essentials.experiences FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "geofence_boundaries: public read"
  ON essentials.geofence_boundaries FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "government_bodies: public read"
  ON essentials.government_bodies FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "governments: public read"
  ON essentials.governments FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "identifiers: public read"
  ON essentials.identifiers FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "issues: public read"
  ON essentials.issues FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "judge_details: public read"
  ON essentials.judge_details FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "judicial_disciplinary_records: public read"
  ON essentials.judicial_disciplinary_records FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "judicial_evaluations: public read"
  ON essentials.judicial_evaluations FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "judicial_metrics: public read"
  ON essentials.judicial_metrics FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "legislative_bill_cosponsors: public read"
  ON essentials.legislative_bill_cosponsors FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "legislative_bills: public read"
  ON essentials.legislative_bills FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "legislative_committee_memberships: public read"
  ON essentials.legislative_committee_memberships FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "legislative_committees: public read"
  ON essentials.legislative_committees FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "legislative_leadership_roles: public read"
  ON essentials.legislative_leadership_roles FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "legislative_politician_id_map: public read"
  ON essentials.legislative_politician_id_map FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "legislative_sessions: public read"
  ON essentials.legislative_sessions FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "legislative_votes: public read"
  ON essentials.legislative_votes FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "offices: public read"
  ON essentials.offices FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "politician_committees: public read"
  ON essentials.politician_committees FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "politician_contacts: public read"
  ON essentials.politician_contacts FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "politician_images: public read"
  ON essentials.politician_images FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "politician_stances: public read"
  ON essentials.politician_stances FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "politicians: public read"
  ON essentials.politicians FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "position_descriptions: public read"
  ON essentials.position_descriptions FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "quotes: public read"
  ON essentials.quotes FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "zip_politicians: public read"
  ON essentials.zip_politicians FOR SELECT TO anon, authenticated USING (true);

-- ============================================================
-- Section 3: Grants
-- ============================================================
GRANT USAGE ON SCHEMA essentials TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA essentials TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA essentials GRANT SELECT ON TABLES TO anon, authenticated;

COMMIT;
