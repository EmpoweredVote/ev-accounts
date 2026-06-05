-- Migration 266: Phase 89 IN + ME School Board Headshots
-- AUDIT-ONLY: captures the live politician_images INSERTs performed during Phase 89 Plan 03
-- execution on 2026-06-03.
-- DO NOT apply via Supabase ledger -- actual DB writes happened live via _tmp-in-me-school-headshots.py.
-- Pattern matches 258_ca_city_school_headshots.sql / 262_tx_collin_county_school_headshots.sql.
--
-- 40 officials documented:
--   Indianapolis Public Schools (IPS)              (3 entries: D3 Hope Duke Star, D2 Hasaan Rashid, + IPS context) -- 0/3 uploaded
--   Monroe County Community School Corporation (MCCSC) (1 entry: D7 Aja Jester)                                  -- 0/1 uploaded
--   Lewiston Public Schools (ME)                   (8 officials, -890011..-890018)                                -- 0/8 uploaded
--   Bangor School Department (ME)                  (7 officials, -890021..-890027)                                -- 0/7 uploaded
--   South Portland Public Schools (ME)             (7 officials, -890031..-890037)                                -- 0/7 uploaded
--   Auburn Public Schools (ME)                     (8 officials, -890041..-890048)                                -- 0/8 uploaded
--   Biddeford Public Schools (ME)                  (7 officials, -890051..-890057)                                -- 0/7 uploaded
--
-- Total uploaded: 0/40 officials
-- All districts blocked: every district's official website uses a JavaScript-only CMS
-- (Schoolblocks/Next.js, Thrillshare/Fastly client challenge, SmartSites, Cloudflare)
-- that returns only a JS client challenge shell when accessed server-side. No individual
-- board member photos could be retrieved programmatically at execution time (2026-06-03).
--
-- IPS specifically: myips.org returns HTTP 403 Forbidden on server-side fetch AND
-- RESEARCH.md confirmed all member img tags show transparent GIF placeholders.
-- No IPS photos available on official site.
--
-- Photo processing spec (if photos had been available):
-- crop to 4:5 ratio (center-crop wide / top-crop tall), then resize 600x750 Lanczos q90.
-- Storage bucket: politician_photos; path: {politician_id}-headshot.jpg.
-- politician_images.type = 'default' (UI filter: .find(img => img.type === 'default')).
--
-- Run: 2026-06-03

-- Safety guard: this file is AUDIT-ONLY. Abort if applied directly.
DO $$
BEGIN
  RAISE EXCEPTION 'Migration 266 is AUDIT-ONLY and must not be applied. Actual DB writes happened live via _tmp-in-me-school-headshots.py during Phase 89 Plan 03.';
END $$;

-- ====================== INDIANAPOLIS PUBLIC SCHOOLS (IPS) ======================
-- Official site: https://myips.org/district-school-board/school-board/
-- Status: 0/2 Phase 89 IPS officials have photos available on official site.
-- Reason: myips.org returns HTTP 403 Forbidden on server-side fetch AND uses
-- transparent GIF placeholders for ALL board members (RESEARCH.md confirmed 2026-06-03).
-- No IPS board member photos are available at myips.org for automated retrieval.

-- Hope Duke Star (-890001): No photo found.
-- URL(s) checked: https://myips.org/district-school-board/school-board/
-- Reason: official site (myips.org) shows transparent GIF placeholders for all members;
--         site also returns HTTP 403 Forbidden on server-side fetch

-- Hasaan Rashid (external_id=506586, IPS District 2): No photo found.
-- URL(s) checked: https://myips.org/district-school-board/school-board/
-- Reason: official site (myips.org) shows transparent GIF placeholders for all members;
--         site also returns HTTP 403 Forbidden on server-side fetch

-- Note: If IPS photos become available in the future (e.g., from Wikipedia or local news),
-- the INSERT pattern for any uploaded photos would be:
-- INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
-- SELECT gen_random_uuid(),
--        (SELECT id FROM essentials.politicians WHERE external_id = -890001),
--        'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' ||
--          (SELECT id FROM essentials.politicians WHERE external_id = -890001)::text || '-headshot.jpg',
--        'default', 'public_domain'
-- WHERE NOT EXISTS (
--   SELECT 1 FROM essentials.politician_images
--   WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -890001)
-- );

-- ====================== MONROE COUNTY COMMUNITY SCHOOL CORPORATION (MCCSC) ======================
-- Official site: https://www.mccsc.edu/board
-- Status: 0/1 Phase 89 MCCSC officials have photos available on official site.
-- Reason: mccsc.edu uses SmartSites CMS which renders board member profiles entirely via
-- JavaScript. Server-side fetch returns only the site shell (logo, navigation) with no
-- board member content accessible programmatically.

-- Aja Jester (external_id=437675, MCCSC District 7): No photo found.
-- URL(s) checked: https://www.mccsc.edu/board
-- Reason: SmartSites CMS (mccsc.edu) renders board member profiles via JavaScript only;
--         server-side HTML contains no member names, photos, or profile content

-- ====================== LEWISTON PUBLIC SCHOOLS ======================
-- Official site: https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b
-- Status: 0/8 officials have photos available on official site.
-- Reason: lewistonpublicschools.org uses Schoolblocks Next.js CMS which is fully
-- JavaScript-rendered. Server-side fetch returns the full page HTML (228KB) but
-- board member names, photos, and profile data are loaded dynamically via React
-- hydration. No member names or photo URLs are present in the static HTML.

-- Phoenix McLaughlin (-890011): No photo found.
-- URL(s) checked: https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b
-- Reason: Schoolblocks Next.js CMS — member content loaded via JavaScript only

-- Janet Beaudoin (-890012): No photo found.
-- URL(s) checked: https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b
-- Reason: Schoolblocks Next.js CMS — member content loaded via JavaScript only

-- Elizabeth Eames (-890013): No photo found.
-- URL(s) checked: https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b
-- Reason: Schoolblocks Next.js CMS — member content loaded via JavaScript only

-- Julia Harper (-890014): No photo found.
-- URL(s) checked: https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b
-- Reason: Schoolblocks Next.js CMS — member content loaded via JavaScript only

-- VACANT - Ward 5 (-890015): No photo. Vacant seat — no person to photograph.
-- URL(s) checked: N/A (vacant placeholder; is_vacant=true)
-- Reason: vacant seat

-- Meghan Hird (-890016): No photo found.
-- URL(s) checked: https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b
-- Reason: Schoolblocks Next.js CMS — member content loaded via JavaScript only

-- Donna Gallant (-890017): No photo found.
-- URL(s) checked: https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b
-- Reason: Schoolblocks Next.js CMS — member content loaded via JavaScript only

-- Luke Jensen (-890018): No photo found.
-- URL(s) checked: https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b
-- Reason: Schoolblocks Next.js CMS — member content loaded via JavaScript only

-- ====================== BANGOR SCHOOL DEPARTMENT ======================
-- Official site: https://www.bangorschools.net/page/school-committee
-- Status: 0/7 officials have photos available on official site.
-- Reason: bangorschools.net uses Thrillshare CMS with a Fastly client challenge
-- (JavaScript-based bot protection). Server-side fetch returns the client challenge
-- shell page (3KB, "Client Challenge" title) with no board member content.

-- Tim Surrette (-890021): No photo found.
-- URL(s) checked: https://www.bangorschools.net/page/school-committee
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Katie Brydon (-890022): No photo found.
-- URL(s) checked: https://www.bangorschools.net/page/school-committee
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Mallory Cook (-890023): No photo found.
-- URL(s) checked: https://www.bangorschools.net/page/school-committee
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Ben Speed (-890024): No photo found.
-- URL(s) checked: https://www.bangorschools.net/page/school-committee
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Ben Sprague (-890025): No photo found.
-- URL(s) checked: https://www.bangorschools.net/page/school-committee
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Shelly Okere (-890026): No photo found.
-- URL(s) checked: https://www.bangorschools.net/page/school-committee
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Sara Luciano (-890027): No photo found.
-- URL(s) checked: https://www.bangorschools.net/page/school-committee
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- ====================== SOUTH PORTLAND PUBLIC SCHOOLS ======================
-- Official site: https://www.spsd.org/board/members-of-the-board
-- Status: 0/7 officials have photos available on official site.
-- Reason: spsd.org uses a JavaScript-heavy CMS with Fastly/CDN bot protection.
-- Server-side fetch returns the client challenge shell page (3KB) with no board
-- member content. Both spsd.org and spsdme.org are behind the same JS challenge.

-- Susan Rauscher (-890031): No photo found.
-- URL(s) checked: https://www.spsd.org/board/members-of-the-board
-- Reason: JS-heavy CMS with Fastly client challenge — server-side fetch blocked

-- Tyler Smith (-890032): No photo found.
-- URL(s) checked: https://www.spsd.org/board/members-of-the-board
-- Reason: JS-heavy CMS with Fastly client challenge — server-side fetch blocked

-- Rosemarie De Angelis (-890033): No photo found.
-- URL(s) checked: https://www.spsd.org/board/members-of-the-board
-- Reason: JS-heavy CMS with Fastly client challenge — server-side fetch blocked

-- George Risch (-890034): No photo found.
-- URL(s) checked: https://www.spsd.org/board/members-of-the-board
-- Reason: JS-heavy CMS with Fastly client challenge — server-side fetch blocked

-- VACANT - District 5 (-890035): No photo. Vacant seat — no person to photograph.
-- URL(s) checked: N/A (vacant placeholder; is_vacant=true)
-- Reason: Adrian Dowling resigned April 2026; seat unfilled at implementation time

-- Jennifer Ryan (-890036): No photo found.
-- URL(s) checked: https://www.spsd.org/board/members-of-the-board
-- Reason: JS-heavy CMS with Fastly client challenge — server-side fetch blocked

-- Eleni Richardson (-890037): No photo found.
-- URL(s) checked: https://www.spsd.org/board/members-of-the-board
-- Reason: JS-heavy CMS with Fastly client challenge — server-side fetch blocked

-- ====================== AUBURN PUBLIC SCHOOLS ======================
-- Official site: https://auburnschl.edu/district_info/school_committee
-- Status: 0/8 officials have photos available on official site.
-- Reason: auburnschl.edu is protected by Cloudflare bot detection ("Just a moment..."
-- challenge page). Server-side fetch returns the Cloudflare challenge HTML with
-- no board member content accessible.

-- Korin McGuigan (-890041): No photo found.
-- URL(s) checked: https://auburnschl.edu/district_info/school_committee
-- Reason: Cloudflare bot protection — server-side fetch returns challenge page

-- Misty Edgecomb (-890042): No photo found.
-- URL(s) checked: https://auburnschl.edu/district_info/school_committee
-- Reason: Cloudflare bot protection — server-side fetch returns challenge page

-- Patricia Gautier (-890043): No photo found.
-- URL(s) checked: https://auburnschl.edu/district_info/school_committee
-- Reason: Cloudflare bot protection — server-side fetch returns challenge page

-- Lydia Chapman (-890044): No photo found.
-- URL(s) checked: https://auburnschl.edu/district_info/school_committee
-- Reason: Cloudflare bot protection — server-side fetch returns challenge page

-- Daniel F. Poisson Sr. (-890045): No photo found.
-- URL(s) checked: https://auburnschl.edu/district_info/school_committee
-- Reason: Cloudflare bot protection — server-side fetch returns challenge page

-- Pamela Albert (-890046): No photo found.
-- URL(s) checked: https://auburnschl.edu/district_info/school_committee
-- Reason: Cloudflare bot protection — server-side fetch returns challenge page

-- Olivia Jaye Rich (-890047): No photo found.
-- URL(s) checked: https://auburnschl.edu/district_info/school_committee
-- Reason: Cloudflare bot protection — server-side fetch returns challenge page

-- Nancy Pulk (-890048): No photo found.
-- URL(s) checked: https://auburnschl.edu/district_info/school_committee
-- Reason: Cloudflare bot protection — server-side fetch returns challenge page

-- ====================== BIDDEFORD PUBLIC SCHOOLS ======================
-- Official site: https://biddefordschools.me (School Committee page at /domain/128)
-- Status: 0/7 officials have photos available on official site.
-- Reason: biddefordschools.me uses Thrillshare CMS with a Fastly client challenge
-- (same JavaScript bot protection as Bangor). Server-side fetch returns the
-- client challenge shell (3KB) with no board member content.

-- Amy Clearwater (-890051): No photo found.
-- URL(s) checked: https://biddefordschools.me/domain/128
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Meagan Desjardins (-890052): No photo found.
-- URL(s) checked: https://biddefordschools.me/domain/128
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Michele Landry (-890053): No photo found.
-- URL(s) checked: https://biddefordschools.me/domain/128
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Marie Potvin (-890054): No photo found.
-- URL(s) checked: https://biddefordschools.me/domain/128
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Timothy Stebbins (-890055): No photo found.
-- URL(s) checked: https://biddefordschools.me/domain/128
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Karen Ruel (-890056): No photo found.
-- URL(s) checked: https://biddefordschools.me/domain/128
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- Emily Henley (-890057): No photo found.
-- URL(s) checked: https://biddefordschools.me/domain/128
-- Reason: Thrillshare CMS with Fastly client challenge — server-side fetch blocked

-- =============== SUMMARY ===============
-- Total Phase 89 officials: 40 (3 IN + 37 ME)
-- Headshots uploaded: 0
-- No photo: 40
--   IPS D3 Hope Duke Star (-890001):   0/1 (myips.org: 403 + transparent GIF placeholders)
--   IPS D2 Hasaan Rashid (ext=506586): 0/1 (myips.org: 403 + transparent GIF placeholders)
--   MCCSC D7 Aja Jester (ext=437675):  0/1 (mccsc.edu SmartSites: JS-only CMS)
--   Lewiston (8 officials):            0/8 (Schoolblocks Next.js: JS-only CMS)
--   Bangor (7 officials):              0/7 (Thrillshare + Fastly client challenge)
--   South Portland (7 officials):      0/7 (Fastly JS client challenge)
--   Auburn (8 officials):              0/8 (Cloudflare bot protection)
--   Biddeford (7 officials):           0/7 (Thrillshare + Fastly client challenge)
--
-- Live DB verified: SELECT COUNT(*) FROM essentials.politician_images pi
--   JOIN essentials.politicians p ON p.id = pi.politician_id
--   WHERE (p.external_id = -890001 OR p.external_id BETWEEN -890057 AND -890011)
--   AND pi.type = 'default'
-- Result: 0 (all sites CMS-blocked; no uploads performed)
-- =====================================
