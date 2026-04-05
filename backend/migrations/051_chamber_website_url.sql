-- 051_chamber_website_url.sql
-- Add website_url column to chambers for sub-group level links

ALTER TABLE essentials.chambers ADD COLUMN IF NOT EXISTS website_url TEXT;

COMMENT ON COLUMN essentials.chambers.website_url IS 'Optional URL for this chamber/body (e.g., bloomington.in.gov/council)';
