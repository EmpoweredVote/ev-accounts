-- 1532_resource_actonmass_legislators_to_archive.sql
--
-- Re-point 1106 row-citations from removed actonmass.org/legislators/ pages to the Wayback capture
-- that still carries the scorecard they rest on. 123 URLs. Nothing is retired, no stance value
-- changes, and no row gains or loses a source -- this is array_replace, one string for one string.
--   Review: data/stance-retirement/2026-08-02-actonmass-wayback-resourcing.md
--   Rollback: data/stance-retirement/2026-08-02-actonmass-wayback-rollback.json
--
-- This is the 1519/1531 remedy at scale. Act on Mass removed every /legislators/ page (verified: absent
-- from sitemap-1.xml, absent from site nav, no equivalent path -- unlike /bills/, which was renamed).
-- The research was sound; the pages went away.
--
-- 🔴 THE CAPTURES WERE VERIFIED TO CARRY THE CLAIMS, NOT MERELY TO EXIST. Each of these pages is a
-- co-sponsorship scorecard, and on it a bill's status is carried ONLY by an image class --
-- green_check or red_x -- with the bill name rendered identically either way. So every capture was
-- DOM-parsed into {bill -> signed on?} and checked against what the rows assert:
--   849 rows name a bill and the capture agrees · 19 agree on some bills and not others ·
--   11 are contradicted by it · 227 name no scorecard bill to check.
-- The 11 contradicted rows ARE re-pointed here, deliberately: the citation is a truthful pointer
-- to the source the research used, and a live archive makes the defect visible and checkable instead of
-- hiding it behind a 404. They are listed for correction in the review, not silently published as sound.
--
-- 🔴 CAPTURE CHOSEN BY SCORECARD GENERATION, NOT BY DATE. Act on Mass rebuilt the board seven times
-- between 2021 and 2026 (30 bills -> 26 -> 24 -> 23 -> 19 -> 27), so the newest capture of a page can be
-- a DIFFERENT legislative session's record than the one a row was researched from. Within the current
-- 27-bill generation the marks are effectively frozen -- 5 changes across 405 captures, all late
-- sign-ons in one 2024 window, none of them a bill these rows turn on -- so the latest
-- current-generation capture is cited. 24 URLs (212 rows) are NOT touched by this migration:
--   · 2 have ONLY off-generation captures (Peisch, Livingstone). Peisch's rows say she did NOT
--     co-sponsor the Safe Communities Act "(red X on AOM)"; her only captures are a 2021-22 board with a
--     GREEN CHECK. Citing it would publish a link that refutes the row -- the Jemison rule from 1531.
--   · 22 have no capture in ANY query form. Each was re-queried four ways (bare, trailing slash,
--     prefix, path-prefix) after the prefix sweep, because an empty CDX body is a query-form artifact as
--     often as a real absence; all 100 queries returned parseable, genuinely empty JSON.
--
-- ⚠ THREE OF THESE URLS WERE NEVER VALID, WHICH IS A DIFFERENT DEFECT FROM LINK ROT. dave-rogers,
-- steven-owens and danillo-sena are misspellings of pages that exist under the site's own slug --
-- david-rogers, steve-owens, dan-sena -- for the SAME politician, confirmed both by shared
-- politician_id and by the archived page naming them ("Dan Sena | Act On Mass", "Rep. Sena"). They are
-- re-pointed at the real page's capture. Note john-rogers is a DIFFERENT legislator and is not used.

BEGIN;

CREATE TEMP TABLE aom_map(dead text PRIMARY KEY, live text NOT NULL, expected int NOT NULL) ON COMMIT DROP;

INSERT INTO aom_map(dead, live, expected) VALUES
  ('https://actonmass.org/legislators/marjorie-decker/',
   'https://web.archive.org/web/20250324121332/https://actonmass.org/legislators/marjorie-decker/', 28),
  ('https://actonmass.org/legislators/mike-connolly/',
   'https://web.archive.org/web/20260310181857/https://actonmass.org/legislators/mike-connolly/', 22),
  ('https://actonmass.org/legislators/mindy-domb',
   'https://web.archive.org/web/20250807044049/https://actonmass.org/legislators/mindy-domb/', 22),
  ('https://actonmass.org/legislators/patricia-jehlen/',
   'https://web.archive.org/web/20260412023712/https://actonmass.org/legislators/patricia-jehlen/', 21),
  ('https://actonmass.org/legislators/lindsay-sabadosa',
   'https://web.archive.org/web/20260510012513/https://actonmass.org/legislators/lindsay-sabadosa/', 18),
  ('https://actonmass.org/legislators/estela-reyes/',
   'https://web.archive.org/web/20260510025509/https://actonmass.org/legislators/estela-reyes/', 17),
  ('https://actonmass.org/legislators/erika-uyterhoeven/',
   'https://web.archive.org/web/20260510020804/https://actonmass.org/legislators/erika-uyterhoeven/', 16),
  ('https://actonmass.org/legislators/alan-silvia/',
   'https://web.archive.org/web/20250518071844/https://actonmass.org/legislators/alan-silvia/', 14),
  ('https://actonmass.org/legislators/carmine-gentile/',
   'https://web.archive.org/web/20260510022023/https://actonmass.org/legislators/carmine-gentile/', 14),
  ('https://actonmass.org/legislators/christine-barber/',
   'https://web.archive.org/web/20260310182424/https://actonmass.org/legislators/christine-barber/', 14),
  ('https://actonmass.org/legislators/christopher-hendricks/',
   'https://web.archive.org/web/20260119052118/https://actonmass.org/legislators/christopher-hendricks/', 14),
  ('https://actonmass.org/legislators/christopher-markey/',
   'https://web.archive.org/web/20260412025252/https://actonmass.org/legislators/christopher-markey/', 14),
  ('https://actonmass.org/legislators/jack-lewis',
   'https://web.archive.org/web/20260212225114/https://actonmass.org/legislators/jack-lewis/', 14),
  ('https://actonmass.org/legislators/john-keenan',
   'https://web.archive.org/web/20260510021435/https://actonmass.org/legislators/john-keenan/', 14),
  ('https://actonmass.org/legislators/colleen-garry/',
   'https://web.archive.org/web/20260310193641/https://actonmass.org/legislators/colleen-garry/', 13),
  ('https://actonmass.org/legislators/donald-wong/',
   'https://web.archive.org/web/20250613060826/https://actonmass.org/legislators/donald-wong/', 13),
  ('https://actonmass.org/legislators/james-arciero/',
   'https://web.archive.org/web/20251114031938/https://actonmass.org/legislators/james-arciero/', 13),
  ('https://actonmass.org/legislators/lydia-edwards',
   'https://web.archive.org/web/20260412021327/https://actonmass.org/legislators/lydia-edwards/', 13),
  ('https://actonmass.org/legislators/michael-brady',
   'https://web.archive.org/web/20250613074402/https://actonmass.org/legislators/michael-brady/', 13),
  ('https://actonmass.org/legislators/sean-garballey',
   'https://web.archive.org/web/20241031001535/https://actonmass.org/legislators/sean-garballey/', 13),
  ('https://actonmass.org/legislators/simon-cataldo',
   'https://web.archive.org/web/20260212221239/https://actonmass.org/legislators/simon-cataldo/', 13),
  ('https://actonmass.org/legislators/adam-scanlon/',
   'https://web.archive.org/web/20260412025105/https://actonmass.org/legislators/adam-scanlon/', 12),
  ('https://actonmass.org/legislators/bruce-ayers/',
   'https://web.archive.org/web/20251114032517/https://actonmass.org/legislators/bruce-ayers/', 12),
  ('https://actonmass.org/legislators/david-robertson/',
   'https://web.archive.org/web/20260510031346/https://actonmass.org/legislators/david-robertson/', 12),
  ('https://actonmass.org/legislators/francisco-paulino/',
   'https://web.archive.org/web/20250418064320/https://actonmass.org/legislators/francisco-paulino/', 12),
  ('https://actonmass.org/legislators/jennifer-armini/',
   'https://web.archive.org/web/20250613065544/https://actonmass.org/legislators/jennifer-armini/', 12),
  ('https://actonmass.org/legislators/michael-moran',
   'https://web.archive.org/web/20250124162119/https://actonmass.org/legislators/michael-moran/', 12),
  ('https://actonmass.org/legislators/michelle-ciccolo',
   'https://web.archive.org/web/20260510022843/https://actonmass.org/legislators/michelle-ciccolo/', 12),
  ('https://actonmass.org/legislators/alyson-sullivan/',
   'https://web.archive.org/web/20260412031740/https://actonmass.org/legislators/alyson-sullivan/', 11),
  ('https://actonmass.org/legislators/antonio-cabral/',
   'https://web.archive.org/web/20260510023442/https://actonmass.org/legislators/antonio-cabral/', 11),
  ('https://actonmass.org/legislators/brandy-fluker-oakley',
   'https://web.archive.org/web/20260310192036/https://actonmass.org/legislators/brandy-fluker-oakley/', 11),
  ('https://actonmass.org/legislators/christine-barber',
   'https://web.archive.org/web/20260310182424/https://actonmass.org/legislators/christine-barber/', 11),
  ('https://actonmass.org/legislators/cindy-friedman',
   'https://web.archive.org/web/20260510015519/https://actonmass.org/legislators/cindy-friedman/', 11),
  ('https://actonmass.org/legislators/danielle-gregoire',
   'https://web.archive.org/web/20250211013313/https://actonmass.org/legislators/danielle-gregoire/', 11),
  ('https://actonmass.org/legislators/dave-rogers',
   'https://web.archive.org/web/20250518063838/https://actonmass.org/legislators/david-rogers/', 11),
  ('https://actonmass.org/legislators/david-linsky',
   'https://web.archive.org/web/20241031001439/https://actonmass.org/legislators/david-linsky/', 11),
  ('https://actonmass.org/legislators/david-vieira/',
   'https://web.archive.org/web/20241030235834/https://actonmass.org/legislators/david-vieira/', 11),
  ('https://actonmass.org/legislators/jacob-oliveira',
   'https://web.archive.org/web/20250613061730/https://actonmass.org/legislators/jacob-oliveira/', 11),
  ('https://actonmass.org/legislators/james-hawkins/',
   'https://web.archive.org/web/20260510023639/https://actonmass.org/legislators/james-hawkins/', 11),
  ('https://actonmass.org/legislators/john-cronin',
   'https://web.archive.org/web/20251211115807/https://actonmass.org/legislators/john-cronin/', 11),
  ('https://actonmass.org/legislators/john-velis',
   'https://web.archive.org/web/20260510025006/https://actonmass.org/legislators/john-velis/', 11),
  ('https://actonmass.org/legislators/rebecca-rausch',
   'https://web.archive.org/web/20260510021849/https://actonmass.org/legislators/rebecca-rausch/', 11),
  ('https://actonmass.org/legislators/steve-owens',
   'https://web.archive.org/web/20260212225827/https://actonmass.org/legislators/steve-owens/', 11),
  ('https://actonmass.org/legislators/aaron-saunders/',
   'https://web.archive.org/web/20250316115916/https://actonmass.org/legislators/aaron-saunders/', 10),
  ('https://actonmass.org/legislators/andres-vargas',
   'https://web.archive.org/web/20260212214405/https://actonmass.org/legislators/andres-vargas/', 10),
  ('https://actonmass.org/legislators/carlos-gonzalez/',
   'https://web.archive.org/web/20241030235830/https://actonmass.org/legislators/carlos-gonzalez/', 10),
  ('https://actonmass.org/legislators/erika-uyterhoeven',
   'https://web.archive.org/web/20260510020804/https://actonmass.org/legislators/erika-uyterhoeven/', 10),
  ('https://actonmass.org/legislators/frank-moran/',
   'https://web.archive.org/web/20250418071357/https://actonmass.org/legislators/frank-moran/', 10),
  ('https://actonmass.org/legislators/james-murphy/',
   'https://web.archive.org/web/20251114021146/https://actonmass.org/legislators/james-murphy/', 10),
  ('https://actonmass.org/legislators/julian-cyr',
   'https://web.archive.org/web/20260510022634/https://actonmass.org/legislators/julian-cyr/', 10),
  ('https://actonmass.org/legislators/liz-miranda',
   'https://web.archive.org/web/20260510015050/https://actonmass.org/legislators/liz-miranda/', 10),
  ('https://actonmass.org/legislators/nick-collins',
   'https://web.archive.org/web/20260510023746/https://actonmass.org/legislators/nick-collins/', 10),
  ('https://actonmass.org/legislators/russell-holmes',
   'https://web.archive.org/web/20260212220128/https://actonmass.org/legislators/russell-holmes/', 10),
  ('https://actonmass.org/legislators/bradley-jones/',
   'https://web.archive.org/web/20260510014317/https://actonmass.org/legislators/bradley-jones/', 9),
  ('https://actonmass.org/legislators/brendan-crighton',
   'https://web.archive.org/web/20250316134128/https://actonmass.org/legislators/brendan-crighton/', 9),
  ('https://actonmass.org/legislators/brian-ashe/',
   'https://web.archive.org/web/20250418073717/https://actonmass.org/legislators/brian-ashe/', 9),
  ('https://actonmass.org/legislators/christopher-flanagan/',
   'https://web.archive.org/web/20251114032322/https://actonmass.org/legislators/christopher-flanagan/', 9),
  ('https://actonmass.org/legislators/christopher-worrell',
   'https://web.archive.org/web/20260212210253/https://actonmass.org/legislators/christopher-worrell/', 9),
  ('https://actonmass.org/legislators/chynah-tyler',
   'https://web.archive.org/web/20260510032428/https://actonmass.org/legislators/chynah-tyler/', 9),
  ('https://actonmass.org/legislators/daniel-cahill',
   'https://web.archive.org/web/20250316123842/https://actonmass.org/legislators/daniel-cahill/', 9),
  ('https://actonmass.org/legislators/danillo-sena/',
   'https://web.archive.org/web/20260510024106/https://actonmass.org/legislators/dan-sena/', 9),
  ('https://actonmass.org/legislators/david-decoste',
   'https://web.archive.org/web/20251114034234/https://actonmass.org/legislators/david-decoste/', 9),
  ('https://actonmass.org/legislators/david-leboeuf',
   'https://web.archive.org/web/20251114014025/https://actonmass.org/legislators/david-leboeuf/', 9),
  ('https://actonmass.org/legislators/jessica-giannino',
   'https://web.archive.org/web/20250124172138/https://actonmass.org/legislators/jessica-giannino/', 9),
  ('https://actonmass.org/legislators/judith-garcia',
   'https://web.archive.org/web/20260510020322/https://actonmass.org/legislators/judith-garcia/', 9),
  ('https://actonmass.org/legislators/kate-lipper-garabedian/',
   'https://web.archive.org/web/20251114022621/https://actonmass.org/legislators/kate-lipper-garabedian/', 9),
  ('https://actonmass.org/legislators/michael-barrett',
   'https://web.archive.org/web/20260510012356/https://actonmass.org/legislators/michael-barrett/', 9),
  ('https://actonmass.org/legislators/paul-feeney',
   'https://web.archive.org/web/20260212224111/https://actonmass.org/legislators/paul-feeney/', 9),
  ('https://actonmass.org/legislators/vanna-howard',
   'https://web.archive.org/web/20260510015344/https://actonmass.org/legislators/vanna-howard/', 9),
  ('https://actonmass.org/legislators/adam-gomez',
   'https://web.archive.org/web/20260212220607/https://actonmass.org/legislators/adam-gomez/', 8),
  ('https://actonmass.org/legislators/donald-berthiaume/',
   'https://web.archive.org/web/20250518072529/https://actonmass.org/legislators/donald-berthiaume/', 8),
  ('https://actonmass.org/legislators/jeffrey-roy/',
   'https://web.archive.org/web/20260510013320/https://actonmass.org/legislators/jeffrey-roy/', 8),
  ('https://actonmass.org/legislators/joan-lovely',
   'https://web.archive.org/web/20260510014603/https://actonmass.org/legislators/joan-lovely/', 8),
  ('https://actonmass.org/legislators/joan-meschino/',
   'https://web.archive.org/web/20260510014441/https://actonmass.org/legislators/joan-meschino/', 8),
  ('https://actonmass.org/legislators/joanne-comerford',
   'https://web.archive.org/web/20241031001432/https://actonmass.org/legislators/joanne-comerford/', 8),
  ('https://actonmass.org/legislators/joseph-mcgonagle/',
   'https://web.archive.org/web/20260310194841/https://actonmass.org/legislators/joseph-mcgonagle/', 8),
  ('https://actonmass.org/legislators/peter-durant',
   'https://web.archive.org/web/20260510024118/https://actonmass.org/legislators/peter-durant/', 8),
  ('https://actonmass.org/legislators/barry-finegold',
   'https://web.archive.org/web/20260510013708/https://actonmass.org/legislators/barry-finegold/', 7),
  ('https://actonmass.org/legislators/cynthia-creem',
   'https://web.archive.org/web/20260510023930/https://actonmass.org/legislators/cynthia-creem/', 7),
  ('https://actonmass.org/legislators/dylan-fernandes',
   'https://web.archive.org/web/20260510020642/https://actonmass.org/legislators/dylan-fernandes/', 7),
  ('https://actonmass.org/legislators/james-eldridge',
   'https://web.archive.org/web/20260310180246/https://actonmass.org/legislators/james-eldridge/', 7),
  ('https://actonmass.org/legislators/jason-lewis',
   'https://web.archive.org/web/20260510015606/https://actonmass.org/legislators/jason-lewis/', 7),
  ('https://actonmass.org/legislators/manny-cruz/',
   'https://web.archive.org/web/20241031023940/https://actonmass.org/legislators/manny-cruz/', 7),
  ('https://actonmass.org/legislators/mark-cusack/',
   'https://web.archive.org/web/20241031001442/https://actonmass.org/legislators/mark-cusack/', 7),
  ('https://actonmass.org/legislators/michael-day/',
   'https://web.archive.org/web/20260510012200/https://actonmass.org/legislators/michael-day/', 7),
  ('https://actonmass.org/legislators/patrick-oconnor',
   'https://web.archive.org/web/20260412022647/https://actonmass.org/legislators/patrick-oconnor/', 7),
  ('https://actonmass.org/legislators/paul-donato/',
   'https://web.archive.org/web/20250124165438/https://actonmass.org/legislators/paul-donato/', 7),
  ('https://actonmass.org/legislators/pavel-payano',
   'https://web.archive.org/web/20241031001537/https://actonmass.org/legislators/pavel-payano/', 7),
  ('https://actonmass.org/legislators/richard-haggerty/',
   'https://web.archive.org/web/20260510022049/https://actonmass.org/legislators/richard-haggerty/', 7),
  ('https://actonmass.org/legislators/robyn-kennedy',
   'https://web.archive.org/web/20260212213046/https://actonmass.org/legislators/robyn-kennedy/', 7),
  ('https://actonmass.org/legislators/steven-ultrino/',
   'https://web.archive.org/web/20260212225811/https://actonmass.org/legislators/steven-ultrino/', 7),
  ('https://actonmass.org/legislators/william-galvin/',
   'https://web.archive.org/web/20250124162751/https://actonmass.org/legislators/william-galvin/', 7),
  ('https://actonmass.org/legislators/andres-vargas/',
   'https://web.archive.org/web/20260212214405/https://actonmass.org/legislators/andres-vargas/', 6),
  ('https://actonmass.org/legislators/brian-murray/',
   'https://web.archive.org/web/20260510014001/https://actonmass.org/legislators/brian-murray/', 6),
  ('https://actonmass.org/legislators/daniel-cahill/',
   'https://web.archive.org/web/20250316123842/https://actonmass.org/legislators/daniel-cahill/', 6),
  ('https://actonmass.org/legislators/david-muradian',
   'https://web.archive.org/web/20251114021236/https://actonmass.org/legislators/david-muradian/', 6),
  ('https://actonmass.org/legislators/ryan-fattman/',
   'https://web.archive.org/web/20241030235831/https://actonmass.org/legislators/ryan-fattman/', 6),
  ('https://actonmass.org/legislators/steven-owens/',
   'https://web.archive.org/web/20260212225827/https://actonmass.org/legislators/steve-owens/', 6),
  ('https://actonmass.org/legislators/adrian-madaro',
   'https://web.archive.org/web/20241031001618/https://actonmass.org/legislators/adrian-madaro/', 5),
  ('https://actonmass.org/legislators/daniel-hunt',
   'https://web.archive.org/web/20241031001438/https://actonmass.org/legislators/daniel-hunt/', 5),
  ('https://actonmass.org/legislators/daniel-ryan',
   'https://web.archive.org/web/20250316115321/https://actonmass.org/legislators/daniel-ryan/', 5),
  ('https://actonmass.org/legislators/david-biele',
   'https://web.archive.org/web/20241030235828/https://actonmass.org/legislators/david-biele/', 5),
  ('https://actonmass.org/legislators/michael-moore',
   'https://web.archive.org/web/20251114034008/https://actonmass.org/legislators/michael-moore/', 5),
  ('https://actonmass.org/legislators/michael-rush',
   'https://web.archive.org/web/20250714222753/https://actonmass.org/legislators/michael-rush/', 5),
  ('https://actonmass.org/legislators/paul-mark',
   'https://web.archive.org/web/20260510021922/https://actonmass.org/legislators/paul-mark/', 5),
  ('https://actonmass.org/legislators/rob-consalvo',
   'https://web.archive.org/web/20251114040204/https://actonmass.org/legislators/rob-consalvo/', 5),
  ('https://actonmass.org/legislators/hannah-kane/',
   'https://web.archive.org/web/20260510025103/https://actonmass.org/legislators/hannah-kane/', 4),
  ('https://actonmass.org/legislators/james-murphy',
   'https://web.archive.org/web/20251114021146/https://actonmass.org/legislators/james-murphy/', 4),
  ('https://actonmass.org/legislators/jeffrey-turco/',
   'https://web.archive.org/web/20241031001439/https://actonmass.org/legislators/jeffrey-turco/', 4),
  ('https://actonmass.org/legislators/ryan-hamilton/',
   'https://web.archive.org/web/20251114023121/https://actonmass.org/legislators/ryan-hamilton/', 3),
  ('https://actonmass.org/legislators/bruce-tarr/',
   'https://web.archive.org/web/20260412021521/https://actonmass.org/legislators/bruce-tarr/', 2),
  ('https://actonmass.org/legislators/david-rogers/',
   'https://web.archive.org/web/20250518063838/https://actonmass.org/legislators/david-rogers/', 2),
  ('https://actonmass.org/legislators/hannah-kane',
   'https://web.archive.org/web/20260510025103/https://actonmass.org/legislators/hannah-kane/', 2),
  ('https://actonmass.org/legislators/jack-lewis/',
   'https://web.archive.org/web/20260212225114/https://actonmass.org/legislators/jack-lewis/', 2),
  ('https://actonmass.org/legislators/kristin-kassner/',
   'https://web.archive.org/web/20241031030014/https://actonmass.org/legislators/kristin-kassner/', 2),
  ('https://actonmass.org/legislators/sally-kerans/',
   'https://web.archive.org/web/20251010182237/https://actonmass.org/legislators/sally-kerans/', 2),
  ('https://actonmass.org/legislators/steven-howitt/',
   'https://web.archive.org/web/20260510021602/https://actonmass.org/legislators/steven-howitt/', 2),
  ('https://actonmass.org/legislators/david-linsky/',
   'https://web.archive.org/web/20241031001439/https://actonmass.org/legislators/david-linsky/', 1),
  ('https://actonmass.org/legislators/john-lawn/',
   'https://web.archive.org/web/20260510023916/https://actonmass.org/legislators/john-lawn/', 1),
  ('https://actonmass.org/legislators/priscila-sousa/',
   'https://web.archive.org/web/20260510022300/https://actonmass.org/legislators/priscila-sousa/', 1),
  ('https://actonmass.org/legislators/rodney-elliott/',
   'https://web.archive.org/web/20260510012922/https://actonmass.org/legislators/rodney-elliott/', 1),
  ('https://actonmass.org/legislators/sean-garballey/',
   'https://web.archive.org/web/20241031001535/https://actonmass.org/legislators/sean-garballey/', 1),
  ('https://actonmass.org/legislators/steven-xiarhos/',
   'https://web.archive.org/web/20250211020712/https://actonmass.org/legislators/steven-xiarhos/', 1);

-- Every row cites exactly one of these URLs (verified: 1,318 of 1,318), so one pass suffices.
UPDATE inform.politician_context pc
   SET sources = array_replace(pc.sources, m.dead, m.live)
  FROM aom_map m
 WHERE m.dead = ANY(pc.sources);

DO $$
DECLARE v_n int; v_bad text;
BEGIN
  -- 1. Every re-pointed citation landed, counted per TARGET and scoped to (politician_id, topic_id).
  --    ⚠ Grouped by the TARGET, not by the dead URL: 11 targets are shared by two dead URLs each -- the 9
  --    trailing-slash pairs (/mindy-domb vs /mindy-domb/) and the 2 slug fixes whose correct spelling
  --    was ALSO cited (dave-rogers + david-rogers, steven-owens + steve-owens). Asserting per dead URL
  --    counts both forms against each and fails on every one of them.
  SELECT string_agg(format('%s: expected %s, found %s', g.live, g.expected, x.n), E'\n')
    INTO v_bad
    FROM (SELECT live, sum(expected)::int AS expected FROM aom_map GROUP BY live) g
    JOIN LATERAL (
      SELECT count(*)::int AS n
        FROM inform.politician_context pc
        JOIN inform.politician_answers pa
          ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.value <> 0
       WHERE g.live = ANY(pc.sources)
    ) x ON true
   WHERE x.n <> g.expected;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'per-URL count mismatch:%', E'\n' || v_bad; END IF;

  -- 2. Nothing still points at a re-pointed dead URL, in any variant.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
   WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s JOIN aom_map m ON m.dead = s);
  IF v_n <> 0 THEN RAISE EXCEPTION '% row(s) still cite a re-pointed dead URL', v_n; END IF;

  -- 3. The total moved is exactly what was reviewed.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.value <> 0
   WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s JOIN aom_map m ON m.live = s);
  IF v_n <> 1106 THEN RAISE EXCEPTION 'expected 1106 rows citing the archive, found %', v_n; END IF;

  -- 4. 🔴 THE HELD ROWS MUST BE UNTOUCHED. They are the ones this pass deliberately refused to
  --    re-source, and a wildcard UPDATE would have swept them up silently.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.value <> 0
   WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s = ANY(ARRAY[
     'https://actonmass.org/legislators/kate-hogan',
     'https://actonmass.org/legislators/dawne-shand/',
     'https://actonmass.org/legislators/carole-fiola/',
     'https://actonmass.org/legislators/adrianne-ramos/',
     'https://actonmass.org/legislators/bud-williams/',
     'https://actonmass.org/legislators/james-arena-derosa/',
     'https://actonmass.org/legislators/mark-montigny',
     'https://actonmass.org/legislators/alice-peisch/',
     'https://actonmass.org/legislators/sam-montano',
     'https://actonmass.org/legislators/angelo-puppolo/',
     'https://actonmass.org/legislators/karen-spilka',
     'https://actonmass.org/legislators/kevin-honan',
     'https://actonmass.org/legislators/richard-wells/',
     'https://actonmass.org/legislators/ronald-mariano',
     'https://actonmass.org/legislators/tackey-chan/',
     'https://actonmass.org/legislators/aaron-michlewitz',
     'https://actonmass.org/legislators/daniel-donahue',
     'https://actonmass.org/legislators/william-driscoll',
     'https://actonmass.org/legislators/tricia-farley-bouvier/',
     'https://actonmass.org/legislators/james-oday/',
     'https://actonmass.org/legislators/jay-livingstone',
     'https://actonmass.org/legislators/kenneth-gordon/',
     'https://actonmass.org/legislators/thomas-stanley/',
     'https://actonmass.org/legislators/william-brownsberger/'
   ]));
  IF v_n <> 212 THEN RAISE EXCEPTION 'held rows changed: expected 212, found %', v_n; END IF;

  -- 5. No row gained or lost a source: the whole cohort still totals 1,318 legislator citations.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.value <> 0
    CROSS JOIN LATERAL unnest(pc.sources) s
   WHERE s ILIKE '%actonmass.org/legislators%';
  IF v_n <> 1318 THEN RAISE EXCEPTION 'legislator-citation total drifted: expected 1318, found %', v_n; END IF;
END $$;

COMMIT;
