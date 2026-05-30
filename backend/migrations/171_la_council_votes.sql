-- Migration 171: LA City Council vote tables (CVVS scraper)
--
-- Purpose: Store LA City Council vote records scraped from the City Clerk
-- CVVS system (cityclerk.lacity.org/cvvs). Enables "How did this council
-- member vote?" display on Essentials politician profile pages and surfaces
-- the donor→politician→vote loop.

-- LA City Council agenda items (one row per council file number)
CREATE TABLE IF NOT EXISTS meetings.la_council_agenda_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  council_file_number TEXT NOT NULL,
  title TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT la_council_agenda_items_cfn_unique UNIQUE (council_file_number)
);

-- LA City Council vote records (one row per politician × vote event)
CREATE TABLE IF NOT EXISTS meetings.la_council_votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  politician_id UUID NOT NULL REFERENCES essentials.politicians(id),
  council_file_number TEXT,
  agenda_item_id UUID REFERENCES meetings.la_council_agenda_items(id),
  vote_date DATE NOT NULL,
  vote TEXT NOT NULL CHECK (vote IN ('YES', 'NO', 'ABSENT', 'ABSTAIN', 'RECUSE', 'PRESENT')),
  agenda_description TEXT,
  meeting_type TEXT,
  item_number TEXT,
  scraped_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT la_council_votes_unique UNIQUE (politician_id, council_file_number, vote_date, item_number)
);

CREATE INDEX IF NOT EXISTS la_council_votes_politician_idx ON meetings.la_council_votes(politician_id);
CREATE INDEX IF NOT EXISTS la_council_votes_cfn_idx ON meetings.la_council_votes(council_file_number);
CREATE INDEX IF NOT EXISTS la_council_votes_date_idx ON meetings.la_council_votes(vote_date DESC);
